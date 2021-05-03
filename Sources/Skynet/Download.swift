//
//  Download.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

struct Download {

  static func download(
    _ queue: DispatchQueue,
    _ skylink: Skylink,
    _ saveTo: URL,
    _ completion: @escaping (Result<SkyFile, Error>) -> Void) {

    queue.async {
      let urlToDownload = URL(string: "\(Skynet.Config.host)/\(skylink)")!
      let task = URLSession.shared.downloadTask(with: urlToDownload) { (url, response, error) in

        guard let fileURL: URL = url,
          let response = response as? HTTPURLResponse,
          (200 ..< 300) ~= response.statusCode else {

          if let error = error {
            completion(.failure(error))
            return
          }

          completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
          return
        }

        do {
          try FileManager.default.moveItem(at: fileURL, to: saveTo)
          let mimeType: String = URLSession.mimeTypeForPath(path: fileURL.path)
          let skyFile = SkyFile(fileURL: saveTo, fileName: saveTo.lastPathComponent, type: mimeType)
          completion(.success(skyFile))
        } catch {
          completion(.failure(error))
        }

      }
      task.resume()
    }

  }

}
