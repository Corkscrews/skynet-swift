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
    opts: SkyDBOpts,
    _ completion: @escaping (Result<SkyFile, Swift.Error>) -> Void) {

    queue.async {

      Registry.getEntry(
        queue,
        user: user,
        dataKey: dataKey,
        opts: RegistryOpts(hashedDatakey: nil, timeoutInSeconds: opts.timeoutInSeconds)
      ) { (result: Result<SignedRegistryEntry, Swift.Error>) in

        switch result {
        case .success(let entry):

          let skylink: Skylink = String(bytes: entry.entry.data, encoding: .utf16)!

          Download.download(queue, skylink, saveTo) { (result: Result<SkyFile, Swift.Error>) in

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
    opts: RegistryOpts,
    _ completion: @escaping (Result<(), Swift.Error>) -> Void) {

    queue.async {

      Upload.upload(queue, skyFile.fileURL) { result in

        switch result {
        case .success(let response):

          Registry.getEntry(queue, user: user, dataKey: dataKey, opts: opts) { registryResult in

            var revision: Int = 0

            switch registryResult {
            case .success(let signedRegistryEntry):
              revision = signedRegistryEntry.entry.revision + 1
            case .failure(let error):
              print(error)
              revision += 1
            }

            var hashedDataKey: Data?
            if let hdk = opts.hashedDatakey {
              hashedDataKey = dataWithHexString(hex: hdk)
            }

            let rv = RegistryEntry(
              dataKey: dataKey,
              hashedDataKey: hashedDataKey,
              data: response.skylink.data(using: String.Encoding.utf8)!,
              revision: revision)

            let sig = user.sign(rv.hash())

            let srv = SignedRegistryEntry(signature: sig, entry: rv)

            Registry.setEntry(queue, user: user, dataKey: dataKey, srv: srv, opts: opts) { setRegistryResult in

              switch setRegistryResult {
              case .success():
                completion(.success(()))

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
