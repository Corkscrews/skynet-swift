import XCTest
import Skynet

class Tests: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testBlake2b() {

    let data = "Test".data(using: .utf8)!
    let digest = Blake2b().hash(withDigestSize: 256, data: data)
    let string = digest.base64EncodedString()
    print("digest: \(string)")
    let d = digest.hexEncodedString()
    print("digest D: \(d)")

  }
    
  func testUpdateAndDownload() {

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURL = directory.appendingPathComponent("upload.json")

    let data = Data([1,1,1,1])
    try! data.write(to: fileURL, options: .atomic)

    var skylink: Skylink!

    let expectUpload = XCTestExpectation(description: "Wait the file to upload")

    Skynet.upload(fileURL: fileURL) { (result: Result<SkynetResponse, Swift.Error>) in
      switch result {
      case .success(let response):
        XCTAssertFalse(response.skylink.isEmpty)
        XCTAssertFalse(response.merkleroot.isEmpty)
        skylink = response.skylink
      case .failure(let error):
        XCTFail("Upload to Skynet should not fail. Error: \(error)")
      }
      expectUpload.fulfill()
    }

    wait(for: [expectUpload], timeout: 60.0)

    let fileURLDownload = directory.appendingPathComponent("download.json")

    let expectDownload = XCTestExpectation(description: "Wait the file to download")

    Skynet.download(skylink: skylink, saveTo: fileURLDownload) { (result: Result<SkyFile, Swift.Error>) in
      switch result {
      case .success(let response):
        XCTAssertEqual(response.fileURL, fileURLDownload)
      case .failure(let error):
        XCTFail("Upload to Skynet should not fail. Error: \(error)")
      }
      expectDownload.fulfill()
    }

    wait(for: [expectDownload], timeout: 60.0)

  }
    
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
