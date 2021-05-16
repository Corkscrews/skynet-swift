import Foundation

public struct SkyFile: Codable, Equatable {

  public let fileURL: URL
  public let fileName: String
  public let type: String

  public init(fileURL: URL, fileName: String, type: String) {
    self.fileURL = fileURL
    self.fileName = fileName
    self.type = type
  }

}
