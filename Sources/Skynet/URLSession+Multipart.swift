//
//  URLSession+Multipart.swift
//  URLSessionMultipart
//
//  Created by Robert Ryan on 10/6/14.
//  Copyright (c) 2014 Robert Ryan. All rights reserved.
//

import Foundation
#if os(iOS)
import MobileCoreServices
#else
import CoreServices
#endif

extension URLSession {

  /// Create multipart upload task.
  ///
  /// If using background session, you must supply a `localFileURL` with a `URL` where the
  /// body of the request should be saved.
  ///
  /// - parameter URL:                The `URL` for the web service.
  /// - parameter parameters:         The optional dictionary of parameters to be passed in the body of the request.
  /// - parameter fileKeyName:        The name of the key to be used for files included in the request.
  /// - parameter fileURLs:           An optional array of `URL` for local files to be included in `Data`.
  /// - parameter localFileURL:       The optional file `URL` where the body of the request should be stored. If using non-background session, pass `nil` for the `localFileURL`.
  ///
  /// - returns:                      The `URLRequest` that was created. This throws error if there was problem opening file in the `fileURLs`.

public func uploadMultipartTask(url: URL, parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?, localFileURL: URL? = nil) throws -> URLSessionUploadTask {
  let (request, data) = try createMultipartRequestWithURL(url: url, parameters: parameters, fileKeyName: fileKeyName, fileURLs: fileURLs)
    if let localFileURL = localFileURL {
      try data.write(to: localFileURL, options: .atomic)
      return uploadTask(with: request, fromFile: localFileURL)
    }
    return uploadTask(with: request, from: data)
  }

  /// Create multipart upload task.
  ///
  /// This should not be used with background sessions. Use the rendition without
  /// `completionHandler` if using background sessions.
  ///
  /// - parameter URL:                The `URL` for the web service.
  /// - parameter parameters:         The optional dictionary of parameters to be passed in the body of the request.
  /// - parameter fileKeyName:        The name of the key to be used for files included in the request.
  /// - parameter fileURLs:           An optional array of `URL` for local files to be included in `Data`.
  /// - parameter completionHandler:  The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
  ///
  /// - returns:                      The `URLRequest` that was created. This throws error if there was problem opening file in the `fileURLs`.

  public func uploadMultipartTask(url: URL, parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> URLSessionUploadTask {
    let (request, data) = try createMultipartRequestWithURL(url: url, parameters: parameters, fileKeyName: fileKeyName, fileURLs: fileURLs)
    return uploadTask(with: request, from: data, completionHandler: completionHandler)
  }

  /// Create multipart data task.
  ///
  /// This should not be used with background sessions. Use `uploadMultipartTask` with
  /// `localFileURL` and without `completionHandler` if using background sessions.
  ///
  /// - parameter URL:                The `URL` for the web service.
  /// - parameter parameters:         The optional dictionary of parameters to be passed in the body of the request.
  /// - parameter fileKeyName:        The name of the key to be used for files included in the request.
  /// - parameter fileURLs:           An optional array of `URL` for local files to be included in `Data`.
  ///
  /// - returns:                      The `URLRequest` that was created. This throws error if there was problem opening file in the `fileURLs`.

  public func dataMultipartTaskWithURL(url: URL, parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?) throws -> URLSessionDataTask {
      var (request, data) = try createMultipartRequestWithURL(url: url, parameters: parameters, fileKeyName: fileKeyName, fileURLs: fileURLs)
      request.httpBody = data
    return dataTask(with: request)
  }

  /// Create multipart data task.
  ///
  /// This should not be used with background sessions. Use `uploadMultipartTask` with
  /// `localFileURL` and without `completionHandler` if using background sessions.
  ///
  /// - parameter URL:                The `URL` for the web service.
  /// - parameter parameters:         The optional dictionary of parameters to be passed in the body of the request.
  /// - parameter fileKeyName:        The name of the key to be used for files included in the request.
  /// - parameter fileURLs:           An optional array of `URL` for local files to be included in `Data`.
  /// - parameter completionHandler:  The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
  ///
  /// - returns:                      The `URLRequest` that was created. This throws error if there was problem opening file in the `fileURLs`.

  public func dataMultipartTaskWithURL(url: URL, parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws -> URLSessionDataTask {
    var (request, data) = try createMultipartRequestWithURL(url: url, parameters: parameters, fileKeyName: fileKeyName, fileURLs: fileURLs)
    request.httpBody = data
    return dataTask(with: request, completionHandler: completionHandler)
  }

  /// Create upload request.
  ///
  /// With upload task, we return separate `URLRequest` and `Data` to be passed to `uploadTaskWithRequest(fromData:)`.
  ///
  /// - parameter URL:          The `URL` for the web service.
  /// - parameter parameters:   The optional dictionary of parameters to be passed in the body of the request.
  /// - parameter fileKeyName:  The name of the key to be used for files included in the request.
  /// - parameter fileURLs:     An optional array of `URL` for local files to be included in `Data`.
  ///
  /// - returns:                The `URLRequest` that was created. This throws error if there was problem opening file in the `fileURLs`.

  public func createMultipartRequestWithURL(url: URL, parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?) throws -> (URLRequest, Data) {
    let boundary = URLSession.generateBoundaryString()
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    let data = try createDataWithParameters(parameters: parameters, fileKeyName: fileKeyName, fileURLs: fileURLs, boundary: boundary)
    return (request, data)
  }

  /// Create body of the multipart/form-data request
  ///
  /// - parameter parameters:   The optional dictionary of parameters to be included.
  /// - parameter fileKeyName:  The name of the key to be used for files included in the request.
  /// - parameter boundary:     The multipart/form-data boundary.
  ///
  /// - returns:                The `Data` of the body of the request. This throws error if there was problem opening file in the `fileURLs`.

  private func createDataWithParameters(parameters: [String: AnyObject]?, fileKeyName: String?, fileURLs: [URL]?, boundary: String) throws -> Data {
    let body = NSMutableData()

    if parameters != nil {
      for (key, value) in parameters! {
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        body.appendString(string: "\(value)\r\n")
      }
    }

    if let fileURLs = fileURLs {
      if fileKeyName == nil {
        throw NSError(domain: Bundle.main.bundleIdentifier ?? "URLSession+Multipart", code: -1, userInfo: [NSLocalizedDescriptionKey: "If fileURLs supplied, fileKeyName must not be nil"])
      }

      for fileURL in fileURLs {

        let filename = fileURL.lastPathComponent
        guard let data = try? Data(contentsOf: fileURL) else {
          throw NSError(domain: Bundle.main.bundleIdentifier ?? "URLSession+Multipart", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to open \(fileURL.path)"])
        }

        let mimetype = URLSession.mimeTypeForPath(path: fileURL.path)

        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(fileKeyName!)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.appendString(string: "\r\n")
      }
    }

    body.appendString(string: "--\(boundary)--\r\n")
    return body as Data
  }

  /// Create boundary string for multipart/form-data request
  ///
  /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.

  private class func generateBoundaryString() -> String {
    return "Boundary-\(NSUUID().uuidString)"
  }

  /// Determine mime type on the basis of extension of a file.
  ///
  /// This requires MobileCoreServices (iOS) or CoreServices (macOS) framework.
  ///
  /// - parameter path:         The path of the file for which we are going to determine the mime type.
  ///
  /// - returns:                Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.

  class func mimeTypeForPath(path: String) -> String {
    let url = URL(fileURLWithPath: path)
    let pathExtension = url.pathExtension

    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
      if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
        return mimetype as String
      }
    }
    return "application/octet-stream";
  }

}

extension NSMutableData {

  /// Append string to NSMutableData
  ///
  /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to Data, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
  ///
  /// - parameter string:       The string to be added to the `NSMutableData`.
  public func appendString(string: String) {
    let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
    append(data!)
  }

}
