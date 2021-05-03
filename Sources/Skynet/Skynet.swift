//
//  Skynet.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation
/**
 A `Skynet` instance allows the download and upload of files to the Sia Skynet network.
 - warning: `Skynet.download` has two modes based in file or stream of data.
 */
public struct Skynet {

  // MARK: Download

  /**
   Start the download of a Skylink to a determined path. The file is downloaded temporarily into a
   temporary folder inside your container (iOS and macOS) and later moved to the defined
   `saveTo` path.

   - parameter queue: `DispatchQueue` on which the `SkyFile` value will be published.
   `.main` by default.
   - parameter skylink: Unique identifier for your file in the Sia Skynet network.
   - parameter saveTo: Path where the file will be saved.
   - parameter completion: The code to be executed once the download has completed.
   */
  public static func download(
    queue: DispatchQueue = .main,
    skylink: Skylink,
    saveTo: URL,
    _ completion: @escaping (Result<SkyFile, Swift.Error>) -> Void) {
    Download.download(queue, skylink, saveTo, completion)
  }

  /**
   Start the download of a Skylink using stream. No file is downloaded while the stream happens and
   the data can be written or cached locally inside the closure `didReceiveData`.

   - parameter queue: `DispatchQueue` on which the closures will be published.
   `.main` by default.
   - parameter skylink: Unique identifier for your file in the Sia Skynet network.
   - parameter didReceiveData: The code to be executed once the download of a file part
   has been completed.
   - parameter completion: The code to be executed once the download has completed.
   */
  public static func download(
    queue: DispatchQueue = .main,
    skylink: Skylink,
    didReceiveData: @escaping (Data, Int64) -> Void,
    completion: @escaping (Int64) -> Void) {
    Download().download(queue, skylink, didReceiveData, completion)
  }

  // MARK: Upload

  /**
   Start the upload of a file. Being the `fileURL` the path of your file. Optionally set the
   parameter `fileName` to save the file with a different name in the Sia Skynet network.

   - parameter queue: `DispatchQueue` on which the `SkynetResponse` value will be published.
   `.main` by default.
   - parameter fileURL: Path for your file to be uploaded.
   - parameter fileName: Optional alternative name for your file in the Sia Skynet network.
   - parameter completion: The code to be executed once the upload has completed.
   */
  public static func upload(
    queue: DispatchQueue = .main,
    fileURL: URL,
    fileName: String? = nil,
    _ completion: @escaping (Result<SkynetResponse, Swift.Error>) -> Void) {
    Upload.upload(queue, fileURL, fileName: fileName, completion)
  }

  // MARK: Config

  struct Config {
    static let host = "https://siasky.net"
    static func host(_ route: String) -> String {
      "\(host)\(route)"
    }
  }

}
