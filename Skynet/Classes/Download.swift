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
    _ completion: @escaping (Result<URL, Error>) -> Void) {

    queue.async {
      let url = URL(string: "https://siasky.net/\(skylink)")!
      let task = URLSession.shared.downloadTask(with: url) { (url, response, error) in
        guard let fileURL = url else { return }
        do {
          try FileManager.default.moveItem(at: fileURL, to: saveTo)
          completion(.success(saveTo))
        } catch {
          completion(.failure(error))
        }
      }
      task.resume()
    }

  }

}
