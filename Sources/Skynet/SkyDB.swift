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

public class SkyDB {

  public static func getFile(
    queue: DispatchQueue = .main,
    user: SkynetUser,
    dataKey: String,
    saveTo: URL,
    opts: SkyDBOpts? = nil,
    _ completion: @escaping (Result<SkyFile, Swift.Error>) -> Void) {

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
        case .success(let entry):

          let skylink: Skylink = String(
            bytes: entry.entry.data,
            encoding: .utf8)!

          Download.download(
            queue,
            skylink,
            saveTo
          ) { (result: Result<SkyFile, Swift.Error>) in

            switch result {
            case .success(let skyfile):
              completion(.success(skyfile))
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
    _ completion: @escaping (Result<(), Swift.Error>) -> Void) {

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
        case .success(let response):

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
            case .failure(let error):
//              print(error)
              break
            }

            var hashedDataKey: Data?
            if let hdk = opts.hashedDatakey {
              hashedDataKey = dataWithHexString(hex: hdk)
            }

            let rv = RegistryEntry(
              dataKey: dataKey,
              hashedDataKey: hashedDataKey,
              data: response.skylink.data(
                using: String.Encoding.utf8)!,
              revision: revision)

            let sig = user.sign(rv.hash())

            let srv = SignedRegistryEntry(
              entry: rv,
              signature: sig)

            Registry.setEntry(
              queue,
              user: user,
              dataKey: dataKey,
              srv: srv,
              opts: opts,
              completion)

          }

        case .failure(let error):
          completion(.failure(error))

        }

      }

    }

  }



}
