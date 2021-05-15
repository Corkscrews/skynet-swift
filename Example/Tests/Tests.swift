import XCTest
import Skynet

class Tests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testDecodeHex() {
    let string: String = "testDecodeHex"
    let data: Data = string.data(using: String.Encoding.utf8)!
    let dataEncodedHex: String = data.hexEncodedString()
    let dataEncodedHexData: Data = dataEncodedHex.data(using: String.Encoding.utf8)!
    let dataDecodedHex: Data = dataEncodedHexData.decodeHex()
    let stringDecoded = String(decoding: dataDecodedHex, as: UTF8.self)
    XCTAssertEqual(data, dataDecodedHex)
    XCTAssertEqual(string, stringDecoded)
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

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURL = directory.appendingPathComponent("upload.json")

    let data: Data = randomData(100000)
    try! data.write(to: fileURL, options: .atomic)

    var skylink: Skylink!

    let expectUpload = XCTestExpectation(description: "Wait the file to upload")

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

    wait(for: [expectUpload], timeout: 600.0) // wow

    return skylink
  }

  func testSkyDB() {

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURL = directory.appendingPathComponent("upload.json")

    let data: Data = randomData(100000)
    try! data.write(to: fileURL, options: .atomic)

    let dispatchQueue = DispatchQueue(label: "TestSkyDBDispatchQueue", qos: .userInitiated)

    let user: SkynetUser = SkynetUser.fromSeed(seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

    let dataKey: String = "testRegistry"

    let skyfile = SkyFile(fileURL: fileURL, fileName: "upload.json", type: "application/json")

    let expectedSetFile = XCTestExpectation(description: "Wait to create entry on registry using SkyDB")

    SkyDB.setFile(
      queue: dispatchQueue,
      user: user,
      dataKey: dataKey,
      skyFile: skyfile
    ) { (result: Result<(), Swift.Error>) in
      print(result)
      expectedSetFile.fulfill()
    }

    wait(for: [expectedSetFile], timeout: 60.0)

  }

  func testRegistry() {

    let skylink: Skylink = uploadRandomFile()

    let user: SkynetUser = SkynetUser.fromSeed(seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

    try! user.initialize()

    let dataKey: String = randomString(count: 64)
    let data: Data = skylink.data(using: .utf8)!

    let rv: RegistryEntry = RegistryEntry(dataKey: dataKey, data: data, revision: 0)

    let signature = user.sign(rv.hash())

    let srv = SignedRegistryEntry(entry: rv, signature: signature)

    let expectedSetRegistry = XCTestExpectation(description: "Wait to create entry on registry")

    Registry.setEntry(user: user, dataKey: dataKey, srv: srv) { result in

      switch result {
      case .success:
        break
      case .failure(let error):
        XCTFail("Error while trying to set entry: \(error)")
      }
      expectedSetRegistry.fulfill()

    }

    wait(for: [expectedSetRegistry], timeout: 60.0)

    let expectedGetRegistry = XCTestExpectation(description: "Wait to get entry on registry")

    Registry.getEntry(user: user, dataKey: dataKey) { (result: Result<SignedRegistryEntry, Swift.Error>) in

      switch result {
      case .success(let signedRegistryEntry):
        print("signedRegistryEntry \(signedRegistryEntry)")

        XCTAssertEqual(dataKey, signedRegistryEntry.entry.dataKey!)
        XCTAssertEqual(data, signedRegistryEntry.entry.data)

      case .failure(let error):
        XCTFail("Error while trying to get entry: \(error)")
      }
      expectedGetRegistry.fulfill()

    }

    wait(for: [expectedGetRegistry], timeout: 60.0)

  }

  func testUpdateAndDownload() {

    // This dispatch queue is optional. If not defined, Skynet will dispatch
    // to the main queue, which is not recommended.
    let dispatchQueue = DispatchQueue(label: "TestDispatchQueue", qos: .userInitiated)

    print("Starting upload of file")

    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory
    let fileURL = directory.appendingPathComponent("upload.json")

    let data = randomData(100000)
    try! data.write(to: fileURL, options: .atomic)

    var skylink: Skylink!

    let expectUpload = XCTestExpectation(description: "Wait the file to upload")

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

    wait(for: [expectUpload], timeout: 120.0)

    if skylink == nil {
      fatalError()
    }

    print("File upload completed")
    print("Downloading file")

    let fileURLDownload: URL = directory.appendingPathComponent("download.json")
    try? fileManager.removeItem(at: fileURLDownload)

    let expectFileDownload = XCTestExpectation(description: "Wait the file to download")

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

        XCTAssertEqual(Int(self.size(fileURLDownload.path)), data.count)

      case .failure(let error):
        XCTFail("Upload to Skynet should not fail. Error: \(error)")
      }
      expectFileDownload.fulfill()
    }

    wait(for: [expectFileDownload], timeout: 60.0)

    try? fileManager.removeItem(at: fileURLDownload)

    print("File download completed")
    print("Downloading file as stream")

    let expectStreamDownload = XCTestExpectation(description: "Wait the file to download as stream")

    let mutableData: NSMutableData = NSMutableData()

    Skynet.download(
      queue: dispatchQueue,
      skylink: skylink,
      didReceiveData: { (data: Data, contentLength: Int64) in
        mutableData.append(data)
        XCTAssertGreaterThanOrEqual(contentLength, 0)
        print("Downloaded \(mutableData.length) of \(contentLength) bytes")
      },
      completion: { (totalReceivedData: Int64) in
        expectStreamDownload.fulfill()
        XCTAssertEqual(mutableData.count, data.count)
      }
    )

    wait(for: [expectStreamDownload], timeout: 60.0)

    print("Download of file as stream completed")


  }

  func randomString(count: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<count).map{ _ in letters.randomElement()! })
  }

  public func randomData(_ length: Int) -> Data {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    if status == errSecSuccess {
        return Data(bytes: bytes)
    }
    fatalError()
  }

  func size(_ filePath: String) -> UInt64 {
    do {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
        if let fileSize = fileAttributes[FileAttributeKey.size]  {
            return (fileSize as! NSNumber).uint64Value
        } else {
            print("Failed to get a size attribute from path: \(filePath)")
        }
    } catch {
        print("Failed to get file attributes for local path: \(filePath) with error: \(error)")
    }
    return 0
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
