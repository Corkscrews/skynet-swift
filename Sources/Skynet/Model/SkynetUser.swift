//
//  SkynetUser.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation
import ed25519swift
import CryptoSwift
import TweetNacl

enum SkynetUserError: Error {
  case invalidSeedLength
  case userNotInitialized
}

public enum KeyPairType {
  case ed25519
}

public struct SimplePublicKey {
  let data: Data
  let type: KeyPairType
}

public class SkynetUser {

  public var id: String!
  public var publicKey: SimplePublicKey!
  public var keyPair: (publicKey: [UInt8], secretKey: [UInt8])!
  public var seed: Data!
  public var sk: Data!
  public var pk: Data?

  public static func fromId(userId: String) -> SkynetUser {
    let fixedUserId: String = userId.starts(with: "ed25519-")
      ? String(userId.suffix(8))
      : userId
    let user: SkynetUser = SkynetUser()
    user.id = fixedUserId
    user.publicKey = SimplePublicKey(data: dataWithHexString(hex: userId), type: KeyPairType.ed25519)
    return user
  }

  public static func fromSeed(seed: String) -> SkynetUser {
    fromSeed(dataWithHexString(hex: seed))
  }

  public static func fromSeed(_ data: Data) -> SkynetUser {
    let user: SkynetUser = SkynetUser()
    user.seed = data
    let keyPair = try! NaclSign.KeyPair.keyPair(fromSeed: user.seed)
    user.sk = keyPair.secretKey
    user.pk = keyPair.publicKey
    return user
  }

  public func initialize() throws {
    if seed.count != 32 {
      throw SkynetUserError.invalidSeedLength
    }
    let publicKey: [UInt8] = Ed25519.calcPublicKey(secretKey: seed.bytes)
    self.keyPair = (publicKey, seed.bytes)
    self.publicKey = SimplePublicKey(data: Data(publicKey), type: KeyPairType.ed25519)
    self.id = self.publicKey.data.hexEncodedString()
  }

  public func validate() -> Swift.Error? {
    if seed.count != 32 {
      return SkynetUserError.invalidSeedLength
    }
    if keyPair == nil || publicKey == nil || id == nil {
      return SkynetUserError.userNotInitialized
    }
    return nil
  }

  static func skyIdSeedToEd25519Seed(seedStringInBase64: String) -> Data {
    let bytes = try! PKCS5.PBKDF2(
      password: seedStringInBase64.bytes,
      salt: [],
      iterations: 100,
      keyLength: 32,
      variant: HMAC.Variant.sha256
    ).calculate()
    return Data(bytes)
  }

  public func sign(_ message: Data) -> Signature {
    let signature = Data(Ed25519.sign(message: message.bytes, secretKey: keyPair.secretKey))
    return Signature(
      signature: signature,
      publicKey: SimplePublicKey(data: Data(keyPair.publicKey), type: KeyPairType.ed25519))
  }

  func symEncrypt(key: Data, message: Data) -> Data {
    // Probably wrong
    let nonce = Data(count: 24) // crypto_box_NONCEBYTES
    let cypher = try! NaclSecretBox.secretBox(message: message, nonce: nonce, key: key)
    return nonce + cypher
  }

  func sumDecrypt(key: Data, encryptedMessage: Data) -> Data {
    try! NaclSecretBox.open(
      box: encryptedMessage.advanced(by: 24),
      nonce:encryptedMessage.suffix(24),
      key: key) // Possibly wrong
  }

  static func generateRandomKey() -> Data {
    //  pinenacl.PineNaClUtils.randombytes(pinenacl.SecretBox.keyLength);
    return try! NaclUtilP.randomBytes(length: 32) // crypto_secretbox_KEYBYTES = 32
  }

  func generateOneTimeKey() -> Data {
    // pinenacl.PineNaClUtils.randombytes(pinenacl.SecretBox.keyLength);
    return try! NaclUtilP.randomBytes(length: 32) // crypto_secretbox_KEYBYTES = 32
  }

  static func generateSeed() -> Data {
    return try! NaclUtilP.randomBytes(length: 32)
  }

  func encrypt(message: Data, theirPublicKey: Data) -> Data {

    let nonce = Data(count: 24)
    let keyPair = try! NaclBox.keyPair(fromSecretKey: sk)
    let encrypted = try! NaclBox.box(message: message, nonce: nonce, publicKey: keyPair.publicKey, secretKey: keyPair.secretKey)
    return nonce + encrypted

//      // print('encrypt $seed');
//
//      final box = pinenacl.Box(
//        myPrivateKey: sk,
//        theirPublicKey: pinenacl.PublicKey(theirPublicKey),
//      );
//
//  /*     print(message); */
//
//      final encrypted = box.encrypt(message);
//  /*
//      print(encrypted.nonce);
//      print(encrypted.cipherText); */
//
//      // print(encrypted.nonce.length);
//
//      return [...encrypted.nonce, ...encrypted.cipherText];
    }

  func decrypt(encryptedMessage: Data, theirPublicKey: Data) -> Data {

    let keyPair = try! NaclBox.keyPair(fromSecretKey: sk)
    let decrypted = try! NaclBox.open(
      message: encryptedMessage.advanced(by: 24),
      nonce: encryptedMessage.suffix(24),
      publicKey: keyPair.publicKey,
      secretKey: sk)

    return decrypted

//      // print(theirPublicKey);
//
//      // final theirPubKeyInX25519 = pinenacl.convertPublicKey(theirPublicKey);
//
//      // print(theirPubKeyInX25519);
//
//      final box = pinenacl.Box(
//        myPrivateKey: sk,
//        theirPublicKey: pinenacl.PublicKey(theirPublicKey),
//      );
//
//      final decrypted = box.decrypt(
//        pinenacl.EncryptedMessage(
//          nonce: encryptedMessage.sublist(0, 24),
//          cipherText: encryptedMessage.sublist(24),
//        ),
//      );
//
//      return decrypted;
    }

}

// Replace this with something better
internal func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()
    while(hex.count > 0) {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        var ch: UInt32 = 0
        Scanner(string: c).scanHexInt32(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}

// Reimplement because there is no public call available.
struct NaclUtilP {

  public enum NaclUtilError: Error {
    case badKeySize
    case badNonceSize
    case badPublicKeySize
    case badSecretKeySize
    case internalError
  }


  public static func randomBytes(length: Int) throws -> Data {
    var data = Data(count: length)
    let result = data.withUnsafeMutableBytes {
      return SecRandomCopyBytes(kSecRandomDefault, length, $0)
    }
    guard result == errSecSuccess else {
      throw(NaclUtilError.internalError)
    }

    return data
  }

}
