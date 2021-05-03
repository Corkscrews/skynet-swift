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
  return Blake2b().hash(withDigestSize: 256, data: dataWithPadding)
}

internal func withPadding(_ i: Int) -> Data {
  if i < 0 {
    return Data([])
  }
  var value = UInt64(littleEndian: UInt64(i))
  return Data(withUnsafeBytes(of: &value) { Array($0) })
}

internal func deriveChildSeed(masterSeed: String, derivationPath: String) -> String {

  let data: Data = withPadding(masterSeed.count)
    + masterSeed.data(using: String.Encoding.utf8)!
    + withPadding(derivationPath.count)
    + derivationPath.data(using: String.Encoding.utf8)!

  let digest = Blake2b().hash(withDigestSize: 256, data: data)

  return digest.base64EncodedString()
}
