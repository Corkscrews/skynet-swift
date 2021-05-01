//
//  SkynetResponse.swift
//  Skynet
//
//  Created by Pedro Paulo de Amorim on 01/05/2021.
//

import Foundation

public typealias Skylink = String

public struct SkynetResponse: Decodable {
  public let skylink: Skylink
  public let merkleroot: String
  public let bitfield: Int
}
