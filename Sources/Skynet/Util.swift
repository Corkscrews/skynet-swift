//
//  Util.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 03/05/2021.
//

import Foundation

internal func hashDataKey(_ dataKey: String) -> Data {
  hashRawDataKey(dataKey.data(using: String.Encoding.utf8)!)
}

internal func hashRawDataKey(_ data: Data) -> Data {
  let dataWithPadding: Data = withPadding(data.count) + data
  return Blake2b.hash(withDigestSize: 256, data: dataWithPadding)
}

public func withPadding(_ i: Int) -> Data {
  if i < 0 {
    return Data([])
  }
  var value = i.littleEndian
  return Data(
    bytes: &value,
    count: MemoryLayout.size(ofValue: value))
}

public func deriveChildSeed(masterSeed: String, derivationPath: String) -> String {

  let data: Data = withPadding(masterSeed.count)
    + masterSeed.data(using: String.Encoding.utf8)!
    + withPadding(derivationPath.count)
    + derivationPath.data(using: String.Encoding.utf8)!

  let digest = Blake2b.hash(withDigestSize: 256, data: data)

  return digest.toHexString()
}

extension Data {

  struct HexEncodingOptions: OptionSet {
    let rawValue: Int
    static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
  }

  func hexEncodedString(options: HexEncodingOptions = []) -> String {
    let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
    return self.map { String(format: format, $0) }.joined()
  }

}
