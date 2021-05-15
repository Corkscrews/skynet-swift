import Foundation
import CryptoSwift
import ed25519swift
#if canImport(Blake2b)
import Blake2b
#endif

public struct RegistryEntry: Codable {

  let dataKey: String?
  let hashedDataKey: Data?

  let data: Data
  let revision: Int

  public init(dataKey: String? = nil, hashedDataKey: Data? = nil, data: Data, revision: Int) {
    self.dataKey = dataKey
    self.hashedDataKey = hashedDataKey
    self.data = data
    self.revision = revision
  }

  static func from(data: Data) throws -> Self {
    let decoder = JSONDecoder()
    return try decoder.decode(Self.self, from: data)
  }

  func bytes() -> Data {
    withPadding(revision) + data
  }

  public func hash() -> Data {

    let hashedDataKey: Data
    if let dataKey: String = self.dataKey {
      hashedDataKey = hashDataKey(dataKey)
    } else {
      hashedDataKey = self.hashedDataKey ?? Data([])
    }

    let data = hashedDataKey
      + withPadding(self.data.count)
      + self.data
      + withPadding(self.revision)

    return Blake2b.hash(withDigestSize: 256, data: data)
  }

}

public struct SignedRegistryEntry: Decodable {

  let entry: RegistryEntry
  let signature: Signature?

  public init(data: Data, dataKey: String, user: SkynetUser) {
    let decoder = JSONDecoder()
    let entryResponse: EntryResponse = try! decoder.decode(EntryResponse.self, from: data)
    self.entry = RegistryEntry(dataKey: dataKey, hashedDataKey: nil, data: entryResponse.data, revision: entryResponse.revision)
    self.signature = Signature(signature: entryResponse.signature.signature, publicKey: user.publicKey)
  }

  public init(entry: RegistryEntry, signature: Signature) {
    self.entry = entry
    self.signature = signature
  }

}

public struct Signature: Decodable {
  public let signature: Data
  public let publicKey: Data
}

struct EntryResponse: Decodable {
  let data: Data
  let revision: Int
  let signature: Signature
}

public struct RegistryOpts {
  let hashedDatakey: String?
  let timeoutInSeconds: Int

  public init(hashedDatakey: String? = nil, timeoutInSeconds: Int = 10) {
    self.hashedDatakey = hashedDatakey
    self.timeoutInSeconds = timeoutInSeconds
  }
}

public struct RegistryPayload: Encodable {
  let publicKey: PublicKey
  let dataKey: String
  let revision: Int
  let data: Data
  let signature: Data

  enum CodingKeys: String, CodingKey {
    case publicKey = "publickey"
    case dataKey = "datakey"
    case revision
    case data
    case signature
  }

}

public struct PublicKey: Codable {
  let algorithm: String
  let key: Data
}

public struct Registry {

  private static let route: String = "/skynet/registry"

  public static func setEntry(
    _ queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    srv: SignedRegistryEntry,
    opts: RegistryOpts,
    _ completion: @escaping (Result<(), Swift.Error>) -> Void) {

    queue.async {

      var request: URLRequest = URLRequest(url: URL(string: Skynet.Config.host(route))!)
      request.httpMethod = "POST"

      let payload: RegistryPayload = RegistryPayload(
        publicKey: PublicKey(algorithm: "ed25519", key: user.publicKey),
        dataKey: dataKeyIfRequired(opts, dataKey),
        revision: srv.entry.revision,
        data: srv.entry.data,
        signature: srv.signature!.signature)

      let encoder = JSONEncoder()
      request.httpBody = try! encoder.encode(payload)

      print("request.httpBody \(String(data: request.httpBody!, encoding: .utf8)!)")

      let task = URLSession.shared.dataTask(with: request) { data, response, error in

        print("response \(data!) response \(response)")

        guard let data = data else {
          completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
          return
        }

        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        print("json \(json)")

        guard let response = response as? HTTPURLResponse, response.statusCode == 204 else {

          if let error = error {
            completion(.failure(error))
            return
          }

          completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
          return
        }

        completion(.success(()))
      }

      task.resume()

    }

  }

  public static func getEntry(
    _ queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    opts: RegistryOpts,
    _ completion: @escaping (Result<SignedRegistryEntry, Swift.Error>) -> Void) {

    queue.async {

      var components: URLComponents = URLComponents(string: Skynet.Config.host(route))!
      components.fragment = route

      components.queryItems = [
        URLQueryItem(name: "publickey", value: "ed25519:\(user.id)"),
        URLQueryItem(name: "datakey", value: dataKeyIfRequired(opts, dataKey))
      ]

      let request: URLRequest = URLRequest(url: components.url!)

      let task = URLSession.shared.dataTask(with: request) { data, response, error in

        guard let data = data,
          let response = response as? HTTPURLResponse,
          (200 ..< 300) ~= response.statusCode else {

          if let error = error {
            completion(.failure(error))
            return
          }

          completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
          return
        }

        let srv = SignedRegistryEntry(data: data, dataKey: dataKey, user: user)

        if opts.hashedDatakey != nil { // Why?
          completion(.success(srv))
          return
        }

        let verified: Bool = Ed25519.verify(
          signature: srv.signature!.signature.bytes,
          message: [],
          publicKey: srv.signature!.publicKey.bytes)

        if !verified {
          completion(.failure(NSError(domain: "Invalid signature found", code: 1)))
          return
        }

        completion(.success(srv))

      }
      task.resume()

    }

  }

}

private func dataKeyIfRequired(_ opts: RegistryOpts, _ dataKey: String) -> String {
  opts.hashedDatakey ?? hashDataKey(dataKey).hexEncodedString()
}
