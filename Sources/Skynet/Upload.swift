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

      let task = try? URLSession.shared.uploadMultipartTask(
        url: URL(string: "\(Skynet.Config.host)/skynet/skyfile")!,
        parameters: nil,
        fileKeyName: fileName ?? fileURL.lastPathComponent,
        fileURLs: [fileURL],
        completionHandler: { data, _, error in

          guard let data = data else {
            if let error = error {
              completion(.failure(error))
              return
            }
            completion(.failure(NSError(domain: "Unknown error", code: 1))) // TODO: Replace with enum
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

      task?.resume()

    }

  }

}
