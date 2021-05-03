import Foundation
import CryptoSwift
import ed25519swift

struct RegistryEntry: Codable {

  let dataKey: String?
  let hashedDataKey: String?
  
  let data: Data
  let revision: Int

  init(dataKey: String? = nil, hashedDataKey: String? = nil, data: Data, revision: Int) {
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

  //Stub
  private func withPadding(_ revision: Int) -> Data {
    return Data()
  }

}

public struct SignedRegistryEntry: Decodable {

  let entry: RegistryEntry
  let signature: Signature

  init(data: Data, dataKey: String, user: SkynetUser) {
    let decoder = JSONDecoder()
    let entryResponse: EntryResponse = try! decoder.decode(EntryResponse.self, from: data)
    self.entry = RegistryEntry(dataKey: dataKey, hashedDataKey: nil, data: entryResponse.data, revision: entryResponse.revision)
    self.signature = Signature(signature: entryResponse.signature.signature, publicKey: user.publicKey)
  }

}

struct Signature: Decodable {
  let signature: Data
  let publicKey: Data
}

struct EntryResponse: Decodable {
  let data: Data
  let revision: Int
  let signature: Signature
}

public struct RegistryOpts {
  let hashedDatakey: String?
  let timeoutInSeconds: Int = 10
}

public struct RegistryPayload: Encodable {
  let publicKey: PublicKey
  let datakey: String
  let revision: Int
  let data: Data
  let signature: Data
}

public struct PublicKey: Codable {
  let algorithm: String
  let key: Data
}

struct Registry {

  private static let route: String = "/skynet/registry"

  static func setEntry(
    queue: DispatchQueue,
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
        datakey: opts.hashedDatakey ?? hashDataKey(dataKey).base64EncodedString(),
        revision: srv.entry.revision,
        data: srv.entry.data,
        signature: srv.signature.signature)

      let encoder = JSONEncoder()
      request.httpBody = try! encoder.encode(payload)

      let task = URLSession.shared.dataTask(with: request) { data, response, error in

        guard let _ = data,                            // is there data
          let response = response as? HTTPURLResponse,  // is there HTTP response
          (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
          error == nil else {

          if let error = error {
            completion(.failure(error))
          }

          completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
          return
        }

        completion(.success(()))
      }

      task.resume()

    }

  }

  static func getEntry(
    queue: DispatchQueue,
    user: SkynetUser,
    dataKey: String,
    opts: RegistryOpts,
    _ completion: @escaping (Result<SignedRegistryEntry, Swift.Error>) -> Void) {

    queue.async {

      var components: URLComponents = URLComponents(string: Skynet.Config.host(route))!
      components.fragment = route

      components.queryItems = [
        URLQueryItem(name: "publickey", value: "ed25519:\(user.id)"),
        URLQueryItem(name: "datakey", value: opts.hashedDatakey ?? dataKey),
      ]

      let request: URLRequest = URLRequest(url: components.url!)

      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,                            // is there data
          let response = response as? HTTPURLResponse,  // is there HTTP response
          (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
          error == nil else {

          if let error = error {
            completion(.failure(error))
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
          signature: srv.signature.signature.bytes,
          message: [],
          publicKey: srv.signature.publicKey.bytes)

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

func hashDataKey(_ dataKey: String) -> Data {
  let encoded = dataKey.data(using: String.Encoding.utf8)!
  let padding: Data = Data(Padding.pkcs7.add(to: encoded.bytes, blockSize: AES.blockSize))
  let list = padding + encoded
  Blake2b().hash(withDigestSize: 256, data: list) //Totally wrong
  return encoded
  
}
