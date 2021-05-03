import XCTest
import Skynet

class Tests: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testWithPadding() {
    let integer = 123
    let result = withPadding(integer)
    XCTAssert(!result.isEmpty)
    let hex = result.hexEncodedString()
    XCTAssertEqual(hex, "7b00000000000000")
  }

  func testHashRegistryValue() {

    let entry = RegistryEntry(
      dataKey: "HelloWorld",
      data: "abc".data(using: String.Encoding.utf8)!,
      revision: 123456789)

    let hash: Data = entry.hash()
    let encodedHash = hash.hexEncodedString()

    XCTAssertEqual(encodedHash, "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

  }

  func testDeriveChildSeed() {
    let digest = deriveChildSeed(
      masterSeed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164",
      derivationPath: "skyfeed")
    XCTAssertEqual(digest, "6694f6cfd45be4d920d9c9643ab0f97da36e8d0576054121cba8612eec92fdc6")
  }

  func testBlake2b() {
    let data = "TestBlake2b".data(using: .utf8)!
    let digest = Blake2b.hash(withDigestSize: 256, data: data)
    let base64 = digest.base64EncodedString()
    let hex = digest.hexEncodedString()
    XCTAssertEqual(base64, "luOAY83Qm9vFXolEpw/bBlCPk1DW9McE+UtfgNMbbOw=")
    XCTAssertEqual(hex, "96e38063cdd09bdbc55e8944a70fdb06508f9350d6f4c704f94b5f80d31b6cec")
  }

  func testSkynetUser() {
    // Where is SkynetUser?
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

    let fileURLDownload: URL = directory.appendingPathComponent("download.json")
    try? fileManager.removeItem(at: fileURLDownload)

    let expectDownload = XCTestExpectation(description: "Wait the file to download")

    Skynet.download(skylink: skylink, saveTo: fileURLDownload) { (result: Result<SkyFile, Swift.Error>) in
      switch result {
      case .success(let response):
        XCTAssertEqual(response.fileURL, fileURLDownload)
        XCTAssertEqual(response.fileName, "download.json")
        XCTAssertEqual(response.type, "application/octet-stream")

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
