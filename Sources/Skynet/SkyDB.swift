//
//  SkyDB.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 03/05/2021.
//

import Foundation

public struct SkyDBOpts {
  let timeoutInSeconds: Int
  init(timeoutInSeconds: Int = 10) {
    self.timeoutInSeconds = timeoutInSeconds
  }
}

public struct SkyDBGetResponse {
  public let skylink: Skylink
  public let skyFile: SkyFile
  public let srv: SignedRegistryEntry
}

public struct SkyDBSetResponse {
  public let skynetResponse: SkynetResponse
  public let srv: SignedRegistryEntry
}

public class SkyDB {

  public static func getFile(
    queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    saveTo: URL,
    opts: SkyDBOpts? = nil,
    _ completion: @escaping (Result<SkyDBGetResponse, Swift.Error>) -> Void) {

    queue.async {

      let registryOpts: RegistryOpts?
      if let opts = opts {
        registryOpts = RegistryOpts(
          hashedDatakey: nil,
          timeoutInSeconds: opts.timeoutInSeconds)
      } else {
        registryOpts = nil
      }

      Registry.getEntry(
        queue,
        user: user,
        dataKey: dataKey,
        opts: registryOpts
      ) { (result: Result<SignedRegistryEntry, Swift.Error>) in

        switch result {
        case .success(let srv):

          let skylink: Skylink = String(
            bytes: srv.entry.data,
            encoding: .utf8)!

          Download.download(
            queue,
            skylink,
            saveTo
          ) { (result: Result<SkyFile, Swift.Error>) in

            switch result {
            case .success(let skyfile):
              let response: SkyDBGetResponse = SkyDBGetResponse(
                skylink: skylink,
                skyFile: skyfile,
                srv: srv)
              completion(.success(response))
            case .failure(let error):
              completion(.failure(error))
            }

          }

        case .failure(let error):
          completion(.failure(error))
        }

      }

    }

  }

  public static func setFile(
    queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    skyFile: SkyFile,
    opts: RegistryOpts = RegistryOpts(),
    _ completion: @escaping (Result<SkyDBSetResponse, Swift.Error>) -> Void) {

    queue.async {

      if let error: Swift.Error = user.validate() {
        completion(.failure(error))
        return
      }

      Upload.upload(
        queue,
        skyFile.fileURL
      ) { (result: Result<SkynetResponse, Swift.Error>) in

        switch result {
        case .success(let skynetResponse):

          Registry.getEntry(
            queue,
            user: user,
            dataKey: dataKey,
            opts: opts
          ) { (registryResult: Result<SignedRegistryEntry, Swift.Error>) in

            var revision: Int = 0

            switch registryResult {
            case .success(let signedRegistryEntry):
              revision = signedRegistryEntry.entry.revision + 1
            case .failure(_):
//              print(error)
              break
            }

            var hashedDataKey: Data?

            if let hdk: String = opts.hashedDatakey {
              hashedDataKey = dataWithHexString(hex: hdk)
            }

            let rv: RegistryEntry = RegistryEntry(
              dataKey: dataKey,
              hashedDataKey: hashedDataKey,
              data: skynetResponse.skylink.data(
                using: String.Encoding.utf8)!,
              revision: revision)

            let sig: Signature = user.sign(rv.hash())

            let srv: SignedRegistryEntry = SignedRegistryEntry(
              entry: rv,
              signature: sig)

            Registry.setEntry(
              queue,
              user: user,
              dataKey: dataKey,
              srv: srv,
              opts: opts
            ) { (result: Result<(), Swift.Error>) in

              switch result {
              case .success:

                let response: SkyDBSetResponse = SkyDBSetResponse(
                  skynetResponse: skynetResponse,
                  srv: srv)
                completion(.success(response))

              case .failure(let error):
                completion(.failure(error))

              }

            }

          }

        case .failure(let error):
          completion(.failure(error))

        }

      }

    }

  }

}
