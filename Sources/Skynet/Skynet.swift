//
//  Skynet.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

public struct Skynet {

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
    static let host = ""
  }

}
