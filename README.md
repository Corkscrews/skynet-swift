<p align="center">
  <img src="https://github.com/ppamorim/skynet-swift/blob/main/Assets/skynet.svg" alt="Skynet-Swift" width="200" height="200" />
</p>

<h1 align="center">Skynet SDK for iOS and macOS</h1>

<p align="center">
  <a href="https://github.com/ppamorim/skynet-swift/actions"><img src="https://github.com/ppamorim/skynet-swift/workflows/Tests/badge.svg" alt="GtiHub Workflow Status"></a>
  <a href="https://github.com/ppamorim/skynet-swift/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-informational" alt="License"></a>
  <a href="https://app.bors.tech/repositories/33932"><img src="https://bors.tech/images/badge_small.svg" alt="Bors enabled"></a>
</p>

Use Sia Skynet in your iOS or macOS projects.

## Requirements

## Installation

### Cocoapods

Skynet is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Skynet'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding **Skynet** as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/ppamorim/skynet-swift.git")
]
```

## Usage

To use Skynet features, you can use either `Skynet`, `Registry` or `SkyDB`.

First import the `Skynet` package:

```swift
import Skynet
```

#### Skynet

- Download a file:
 
```swift
// Execute the download outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// Set a temporary file, when running in an application, you can use the documents folder.
let fileURL: URL = FileManager.default
  .temporaryDirectory
  .appendingPathComponent("download.json")

// Skylink for your file in the Skynet portal.
let skylink: Skylink = "AACgj3yd9W4iZXusSUXj3uV0tHq883ReS5I-tFl9m0FBDg"

Skynet.download(
  queue: dispatchQueue,
  skylink: skylink,
  saveTo: fileURL
) { (result: Result<SkyFile, Swift.Error>) in

  // Calls the completion closure in the same queue set, in this case,
  // outside the main thread.

  switch result {
  case .success(let response):

    print("File saved: \(response.fileURL)")

    DispatchQueue.main.async {
      //Update UI
    }

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

- Download a file (stream):
 
```swift
// Execute the download outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// Set a temporary file, when running in an application, you can use the documents folder.
let fileURL: URL = FileManager.default
  .temporaryDirectory
  .appendingPathComponent("download.json")

// Skylink for your file in the Skynet portal.
let skylink: Skylink = "AACgj3yd9W4iZXusSUXj3uV0tHq883ReS5I-tFl9m0FBDg"

var buffer = Data()

Skynet.download(
  queue: dispatchQueue,
  skylink: skylink,
  didReceiveData: { (data: Data, contentLength: Int64) in
    buffer += data
  },
  completion: { (totalReceivedData: Int64) in
    print("File saved, totalReceivedData: \(totalReceivedData)")
  })
```

- Upload a file:

```swift
// Execute the upload outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// Set a temporary file, when running in an application, you can use the documents folder.
let fileURL: URL = FileManager.default
  .temporaryDirectory
  .appendingPathComponent("download.json")

Skynet.upload(
  queue: dispatchQueue,
  fileURL: fileURL
) { (result: Result<SkynetResponse, Swift.Error>) in

  // Calls the completion closure in the same queue set, in this case,
  // outside the main thread.

  switch result {
  case .success(let response):

    print("Skylink: \(response.skylink)")

    DispatchQueue.main.async {
      //Update UI
    }

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

#### Registry

- Get an entry:

```swift
// Execute the upload outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// It's required a Skynet user to create a registry. You can authenticate it using 
// different static functions or building the instance manually.
let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

// Initialize your user when you are ready.
try! user.initialize()

// Key for the entry on registry, it must be unique.
let dataKey: String = "Some Data"

Registry.getEntry(
  queue: dispatchQueue,
  user: user,
  dataKey: dataKey
) { (result: Result<SignedRegistryEntry, Swift.Error>) in

  switch result {

  case .success(let signedRegistryEntry):

    print("Entry: \(signedRegistryEntry.entry)")
    print("Signature: \(signedRegistryEntry.signature)")

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

- Set an entry:

```swift
// Execute the upload outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// It's required a Skylink to create a registry. 
let skylink: Skylink = "AACgj3yd9W4iZXusSUXj3uV0tHq883ReS5I-tFl9m0FBDg"
let data: Data = skylink.data(using: .utf8)!

// It's required a Skynet user to create a registry. You can authenticate it using 
// different static functions or building the instance manually.
let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

// Initialize your user when you are ready.
try! user.initialize()

// Key for the entry on registry, it must be unique.
let dataKey: String = "Some Data"
 
// Register for the data key defined above, mind that sending the same revision for the
// same entry multiple times will cause error. The Revision must change case the dataKey
// doesn't change or if you want to update the entry.
let rv: RegistryEntry = RegistryEntry(dataKey: dataKey, data: data, revision: 0)

// Create the signature for entry.
let signature: Signature = user.sign(rv.hash())

let srv = SignedRegistryEntry(entry: rv, signature: signature)

Registry.setEntry(
  queue: dispatchQueue,
  user: user,
  dataKey: dataKey,
  srv: srv
) { (result: Result<(), Swift.Error>) in

  switch result {

  case .success:
    print("Entry on registry created")

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

#### SkyDB

- Get a file:

```swift
// Execute the upload outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// It's required a Skynet user to create a registry. You can authenticate it using 
// different static functions or building the instance manually.
let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

// Initialize your user when you are ready.
try! user.initialize()

// Key for the entry on registry, it must be unique.
let dataKey: String = "Some Data"

let fileURL: URL = FileManager.default
  .temporaryDirectory
  .appendingPathComponent("download.json")

// Fetch the latest revision of the file.
SkyDB.getFile(
  queue: dispatchQueue,
  user: user,
  dataKey: dataKey,
  saveTo: fileURL
) { (result: Result<SkyDBGetResponse, Swift.Error>) in

  switch result {

  case .success(let response):

    print("File saved to: \(response.skyFile.fileURL)")

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

- Set a file:

```swift
// Execute the upload outside of the main thread.
let dispatchQueue = DispatchQueue(label: "Queue", qos: .userInitiated)

// It's required a Skynet user to create a registry. You can authenticate it using 
// different static functions or building the instance manually.
let user: SkynetUser = SkynetUser.fromSeed(
      seed: "788dddf5232807611557a3dc0fa5f34012c2650526ba91d55411a2b04ba56164")

// Initialize your user when you are ready.
try! user.initialize()

// Key for the entry on registry, it must be unique.
let dataKey: String = "Some Data"

let skyfile: SkyFile = SkyFile(
  fileURL: fileURL,
  fileName: "upload.json",
  type: "application/octet-stream")

let skyfile: SkyFile = SkyFile(
  fileURL: fileURL,
  fileName: "upload.json",
  type: "application/octet-stream")

SkyDB.setFile(
  queue: dispatchQueue,
  user: user,
  dataKey: dataKey,
  skyFile: skyfile
) { (result: Result<SkyDBSetResponse, Swift.Error>) in

  switch result {

  case .success(let response):
    print("Success \(response)")

  case .failure(let error):
    print("Error: \(error)")

  }

}
```

### To be implemented:

 - Upload of files in stream.
 - Batch download/upload of files.
 - Sing-in in the Skynet portal.

## Author

Pedro Paulo de Amorim, pp.amorim@hotmail.com

## License

Skynet is available under the MIT license. See the LICENSE file for more info.
