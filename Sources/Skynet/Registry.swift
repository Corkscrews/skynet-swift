import Foundation
import CryptoSwift

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

struct SignedRegistryEntry {

  let entry: RegistryEntry
//  let signature: Signature

}

struct RegistryOpts {
  let hashedDatakey: String?
  let timeoutInSeconds: Int = 10
}

struct Registry {

  static func getEntry(user: SkynetUser, dataKey: String, opts: RegistryOpts) {

    var url: URLComponents = URLComponents(string: Skynet.Config.host)!

    url.queryItems = [
      URLQueryItem(name: "publickey", value: "ed25519:\(user.id)"),
      URLQueryItem(name: "datakey", value: opts.hashedDatakey ?? dataKey),
    ]

  }

}

func hashDataKey(_ dataKey: String) -> Data {
  let encoded = dataKey.data(using: String.Encoding.utf8)!
  let padding: Data = Data(Padding.pkcs7.add(to: encoded.bytes, blockSize: AES.blockSize))
  let list = padding + encoded
  Blake2b().hash(withDigestSize: 256, data: list) //Totally wrong
  return encoded
  
}
