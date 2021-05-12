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

public class SkynetUser {

  var id: String
  var publicKey: Data
  var keyPair: (publicKey: [UInt8], secretKey: [UInt8])
  var seed: Data = Data()
  var sk: Data = Data()
  var pk: Data?

  func fromId(userId: String) {
    id = userId
    publicKey = dataWithHexString(hex: userId)
  }

  func fromSeed(_ seed: Data) {
    self.seed = seed
    let keyPair = try! NaclSign.KeyPair.keyPair(fromSeed: seed)
    sk = keyPair.secretKey
    pk = keyPair.publicKey
  }

  init() {
    keyPair = Ed25519.generateKeyPair()
    publicKey = Data(Ed25519.calcPublicKey(secretKey: keyPair.secretKey))
    id = publicKey.hexEncodedString()
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

  func sign(_ message: Data) -> Signature {
    let signature = Data(Ed25519.sign(message: message.bytes, secretKey: keyPair.secretKey))
    return Signature(signature: signature, publicKey: Data(keyPair.publicKey))
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
