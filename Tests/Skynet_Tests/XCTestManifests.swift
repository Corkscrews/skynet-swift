import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(skynet_swiftTests.allTests)
    ]
}
#endif
