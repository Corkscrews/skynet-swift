import XCTest
import Skynet

class Tests: XCTestCase {
    
    override func setUp() {
      super.setUp()
    }
    
    override func tearDown() {
      super.tearDown()
    }
    
    func testExample() {

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

      Skynet.download(skylink: skylink, saveTo: fileURLDownload) { (result: Result<URL, Swift.Error>) in
        switch result {
        case .success(let response):
          XCTAssertEqual(response, fileURLDownload)
        case .failure(let error):
          XCTFail("Upload to Skynet should not fail. Error: \(error)")
        }
        expectDownload.fulfill()
      }

      wait(for: [expectDownload], timeout: 60.0)

    }
    
}
