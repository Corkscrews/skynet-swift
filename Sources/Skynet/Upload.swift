//
//  Upload.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

internal struct Upload {

  static func upload(
    _ queue: DispatchQueue,
    _ fileURL: URL,
    fileName: String? = nil,
    _ completion: @escaping (Result<SkynetResponse, Swift.Error>) -> Void) {

    queue.async {

      let urlString: String = "\(Skynet.Config.host)/skynet/skyfile"

      guard let url: URL = URL(string: urlString) else {
        completion(.failure(Skynet.Error.invalidURL(urlString)))
        return
      }

      let sessionConfig = URLSessionConfiguration.default
      sessionConfig.timeoutIntervalForRequest = 120.0
      sessionConfig.timeoutIntervalForResource = 120.0
      let session = URLSession(configuration: sessionConfig)

      do {

      let task = try session.uploadMultipartTask(
        url: url,
        parameters: nil,
        fileKeyName: fileName ?? fileURL.lastPathComponent,
        fileURLs: [fileURL],
        completionHandler: { data, _, error in

          guard let data = data else {
            if let error = error {
              completion(.failure(error))
              return
            }
            completion(.failure(Skynet.Error.unknown(nil))) // TODO: Replace with enum
            return
          }

          do {
            let decoder = JSONDecoder()
            let skynetResponse = try decoder.decode(SkynetResponse.self, from: data)
            completion(.success(skynetResponse))
          } catch {
            print(error)
          }

        })

      task.resume()

      } catch {
        completion(.failure(error))
      }

    }

  }

}
