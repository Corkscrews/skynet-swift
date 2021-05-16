//
//  Download.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

private struct SkynetFileMetadata: Codable {
  let length: Int64
}

final class Download: NSObject, URLSessionDataDelegate {

  // MARK: Stream properties

  private var task: URLSessionTask?
  private var didReceiveData: ((Data, Int64) -> Void)?
  private var completion: ((Int64) -> Void)?

  private var totalReceivedData: Int64 = 0
  private var expectedContentLength: Int64 = -1


  deinit {
    task?.cancel()
    task = nil
    didReceiveData = nil
    completion = nil
  }

  // MARK: Stream download

  func download(
    _ queue: DispatchQueue,
    _ skylink: Skylink,
    _ didReceiveData: @escaping (Data, Int64) -> Void,
    _ completion: @escaping (Int64) -> Void) {

    queue.async {

      if self.didReceiveData != nil || self.task != nil {
        fatalError("When using stream download, you must create a instance of Download for each download.")
      }

      let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
      let urlToDownload = URL(string: "\(Skynet.Config.host)/\(skylink)")!

      self.didReceiveData = didReceiveData
      self.completion = completion

      self.task?.cancel()
      self.task = session.dataTask(with: URLRequest(url: urlToDownload))
      self.task?.resume()

    }
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    self.didReceiveData?(data, expectedContentLength)
    self.totalReceivedData += Int64(data.count)
    if totalReceivedData >= expectedContentLength {
      completion?(totalReceivedData)
      completion = nil //Prevent any additional call if more data gets received.
    }
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    expectedContentLength = response.expectedContentLength
    if expectedContentLength < 0,
       let allHeaderFields = (response as? HTTPURLResponse)?.allHeaderFields,
       let skynetFileMetadata = allHeaderFields.first(where: { key, _ in key as! String == "skynet-file-metadata" }),
       let value: String = skynetFileMetadata.value as? String,
       let data = value.data(using: .utf8),
       let metadata = try? JSONDecoder().decode(SkynetFileMetadata.self, from: data) {
      expectedContentLength = metadata.length
    }
    completionHandler(URLSession.ResponseDisposition.allow)
  }

  // MARK: File download

  static func download(
    _ queue: DispatchQueue,
    _ skylink: Skylink,
    _ saveTo: URL,
    _ completion: @escaping (Result<SkyFile, Error>) -> Void) {

    queue.async {

      let urlString: String = "\(Skynet.Config.host)/\(skylink)"

      guard let urlToDownload: URL = URL(string: urlString) else {
        completion(.failure(Skynet.Error.invalidURL(urlString)))
        return
      }

      let task = URLSession.shared.downloadTask(with: urlToDownload) { (url, response, error) in

        guard let fileURL: URL = url,
          let response = response as? HTTPURLResponse,
          (200 ..< 300) ~= response.statusCode else {

          if let error = error {
            completion(.failure(error))
            return
          }

          completion(.failure(Skynet.Error.unknown(nil)))
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
