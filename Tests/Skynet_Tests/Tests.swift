import XCTest
import Skynet
#if canImport(Blake2b)
import Blake2b
#endif

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

  private func uploadRandomFile() -> Skylink {

    let dispatchQueue = DispatchQueue(label: "uploadRandomFileDispatchQueue", qos: .userInitiated)

    let fileURL: URL = writeFile()

    var skylink: Skylink!

    let expectUpload = self.expectation(description: "Wait the file to upload")

    Skynet.upload(queue: dispatchQueue, fileURL: fileURL) { (result: Result<SkynetResponse, Swift.Error>) in
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

    waitForExpectations(timeout: 120)

    return skylink
  }

  func testSkyDB() {

    let fileURL: URL = writeFile()

    let dispatchQueue = DispatchQueue(
      label: "TestSkyDBDispatchQueue",
      qos: .userInitiated)

    let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

    try! user.initialize()

    let dataKey: String = randomString(count: 64)

    let skyfile: SkyFile = SkyFile(
      fileURL: fileURL,
      fileName: "upload.json",
      type: "application/octet-stream")

    // Upload file for the first time.

    let expectedSetFile = self.expectation(
      description: "Wait to create entry on registry using SkyDB")

    SkyDB.setFile(
      queue: dispatchQueue,
      user: user,
      dataKey: dataKey,
      skyFile: skyfile
    ) { (result: Result<(), Swift.Error>) in

      switch result {
      case .success:
        break
      case .failure(let error):
        XCTFail("First set file should not fail. Error: \(error)")
      }

      expectedSetFile.fulfill()
    }

    waitForExpectations(timeout: 60)

    // Write the file again for the second time to create a new revision.

    let fileURLSecondRevision: URL = writeFile()

    let expectedSetFileSecondRevision = self.expectation(
      description: "Wait to create entry on registry using SkyDB")

    let skyfileSecondRevision: SkyFile = SkyFile(
      fileURL: fileURLSecondRevision,
      fileName: "upload.json",
      type: "application/octet-stream")

    SkyDB.setFile(
      queue: dispatchQueue,
      user: user,
      dataKey: dataKey,
      skyFile: skyfileSecondRevision
    ) { (result: Result<(), Swift.Error>) in

      switch result {
      case .success:
        break
      case .failure(let error):
        XCTFail("Second set file should not fail. Error: \(error)")
      }

      expectedSetFileSecondRevision.fulfill()
    }

    waitForExpectations(timeout: 60)

    // Try to get the latest revision of the file and check if the data
    // points to the latest revision.

    let expectedGetFileSecondRevision = self.expectation(
      description: "Wait to create entry on registry using SkyDB")

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURLSecondRevisionDownloaded: URL = directory
      .appendingPathComponent("upload_second_revision.json")

    try? fileManager.removeItem(at: fileURLSecondRevisionDownloaded)

    SkyDB.getFile(
      queue: dispatchQueue,
      user: user,
      dataKey: dataKey,
      saveTo: fileURLSecondRevisionDownloaded
    ) { (result: Result<SkyFile, Swift.Error>) in

      switch result {
      case .success(let response):

        let expectedSkyfileSecondRevision: SkyFile = SkyFile(
          fileURL: fileURLSecondRevisionDownloaded,
          fileName: "upload_second_revision.json",
          type: "application/octet-stream")

        XCTAssertEqual(response, expectedSkyfileSecondRevision)

        let dataFromSkynet: Data = try! Data(contentsOf: response.fileURL)
        let secondRevisionData: Data = try! Data(contentsOf: fileURLSecondRevision)

        XCTAssertEqual(dataFromSkynet, secondRevisionData)

        break
      case .failure(let error):
        XCTFail("Get file should not fail. Error: \(error)")
      }

      expectedGetFileSecondRevision.fulfill()
    }

    waitForExpectations(timeout: 60)

  }

  func testRegistry() {

    let skylink: Skylink = uploadRandomFile()

    let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

    try! user.initialize()

    let dataKey: String = randomString(count: 64)
    let data: Data = skylink.data(using: .utf8)!
    let revision: Int = 0

    let rv: RegistryEntry = RegistryEntry(dataKey: dataKey, data: data, revision: 0)

    let signature: Signature = user.sign(rv.hash())

    let srv = SignedRegistryEntry(entry: rv, signature: signature)

    let expectedSetRegistry = self.expectation(description: "Wait to create entry on registry")

    Registry.setEntry(user: user, dataKey: dataKey, srv: srv) { (result: Result<(), Swift.Error>) in

      switch result {
      case .success:
        break
      case .failure(let error):
        XCTFail("Error while trying to set entry: \(error)")
      }
      expectedSetRegistry.fulfill()

    }

    waitForExpectations(timeout: 60)

    let expectedGetRegistry = self.expectation(description: "Wait to get entry on registry")

    Registry.getEntry(user: user, dataKey: dataKey) { (result: Result<SignedRegistryEntry, Swift.Error>) in

      switch result {
      case .success(let signedRegistryEntry):

        XCTAssertEqual(dataKey, signedRegistryEntry.entry.dataKey!)
        XCTAssertEqual(data, signedRegistryEntry.entry.data)
        XCTAssertEqual(revision, signedRegistryEntry.entry.revision)

        XCTAssertEqual(signature.publicKey, signedRegistryEntry.signature!.publicKey)
        XCTAssertEqual(signature.signature, signedRegistryEntry.signature!.signature)

      case .failure(let error):
        XCTFail("Error while trying to get entry: \(error)")
      }
      expectedGetRegistry.fulfill()

    }

    waitForExpectations(timeout: 60)

  }

  func testUpdateAndDownload() {

    // This dispatch queue is optional. If not defined, Skynet will dispatch
    // to the main queue, which is not recommended.
    let dispatchQueue = DispatchQueue(label: "TestDispatchQueue", qos: .userInitiated)

    let fileURL: URL = writeFile()

    var skylink: Skylink!

    let expectUpload = self.expectation(description: "Wait the file to upload")

    Skynet.upload(queue: dispatchQueue, fileURL: fileURL) { (result: Result<SkynetResponse, Swift.Error>) in
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

    waitForExpectations(timeout: 240)

    if skylink == nil {
      fatalError()
    }

    let fileURLDownload: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent("download.json")
    try? FileManager.default.removeItem(at: fileURLDownload)

    let expectFileDownload = self.expectation(description: "Wait the file to download")

    Skynet.download(
      queue: dispatchQueue,
      skylink: skylink,
      saveTo: fileURLDownload
    ) { (result: Result<SkyFile, Swift.Error>) in
      switch result {
      case .success(let response):
        XCTAssertEqual(response.fileURL, fileURLDownload)
        XCTAssertEqual(response.fileName, "download.json")
        XCTAssertEqual(response.type, "application/octet-stream")

        XCTAssertEqual(100000, Int(self.size(fileURLDownload.path)))

      case .failure(let error):
        XCTFail("Download from Skynet should not fail. Error: \(error)")
      }
      expectFileDownload.fulfill()
    }

    waitForExpectations(timeout: 60)

    try? FileManager.default.removeItem(at: fileURLDownload)

    // let expectStreamDownload = self.expectation(description: "Wait the file to download as stream")

    // var buffer = Data()

    // Skynet.download(
    //   queue: dispatchQueue,
    //   skylink: skylink,
    //   didReceiveData: { (data: Data, contentLength: Int64) in
    //     buffer += data
    //     XCTAssertGreaterThanOrEqual(contentLength, 0)
    //     print("Downloaded \(buffer.count) of \(contentLength) bytes")
    //   },
    //   completion: { (_: Int64) in
    //     expectStreamDownload.fulfill()
    //     XCTAssertEqual(100000, buffer.count)
    //   }
    // )

    // waitForExpectations(timeout: 60)

  }

  private func writeFile() -> URL {

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURL: URL = directory.appendingPathComponent("upload.json")

    let data: Data = randomData(100000)
    try! data.write(to: fileURL, options: .atomic)

    return fileURL
  }

  private func randomString(count: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<count).map { _ in letters.randomElement()! })
  }

  public func randomData(_ count: Int) -> Data {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    if status == errSecSuccess {
        return Data(bytes)
    }
    fatalError()
  }

  private func size(_ filePath: String) -> UInt64 {
    do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
        if let fileSize = fileAttributes[FileAttributeKey.size] {
            return (fileSize as! NSNumber).uint64Value
        } else {
            print("Failed to get a size attribute from path: \(filePath)")
        }
    } catch {
        print("Failed to get file attributes for local path: \(filePath) with error: \(error)")
    }
    return 0
  }

  static var allTests = [
    ("testWithPadding", testWithPadding),
    ("testHashRegistryValue", testHashRegistryValue),
    ("testDeriveChildSeed", testDeriveChildSeed),
    ("testBlake2b", testBlake2b),
    ("testSkyDB", testSkyDB),
    ("testRegistry", testRegistry),
    ("testUpdateAndDownload", testUpdateAndDownload)
  ]

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
