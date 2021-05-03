//
//  SkyDB.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 03/05/2021.
//

import Foundation

public struct SkyDBOpts {
  let timeoutInSeconds: Int = 10
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
        queue: queue,
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

}
