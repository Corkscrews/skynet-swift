//
//  Skynet.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

public struct Skynet {

  public static func setRegistry(
    queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    srv: SignedRegistryEntry,
    opts: RegistryOpts,
    _ completion: @escaping (Result<(), Swift.Error>) -> Void) {
    Registry.setEntry(queue: queue, user: user, dataKey: dataKey, srv: srv, opts: opts, completion)
  }

  public static func getRegistry(
    queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    opts: RegistryOpts,
    _ completion: @escaping (Result<SignedRegistryEntry, Swift.Error>) -> Void) {
    Registry.getEntry(queue: queue, user: user, dataKey: dataKey, opts: opts, completion)
  }

  public static func download(
    queue: DispatchQueue = .main,
    skylink: Skylink,
    saveTo: URL,
    _ completion: @escaping (Result<URL, Swift.Error>) -> Void) {
    Download.download(queue, skylink, saveTo, completion)
  }

  public static func upload(
    queue: DispatchQueue = .main,
    fileURL: URL,
    fileName: String? = nil,
    _ completion: @escaping (Result<SkynetResponse, Swift.Error>) -> Void) {
    Upload.upload(queue, fileURL, fileName: fileName, completion)
  }

  struct Config {
    static let host = "https://siasky.net"
    static func host(_ route: String) -> String {
      "\(host)\(route)"
    }
  }

}
