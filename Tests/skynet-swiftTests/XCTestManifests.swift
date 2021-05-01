import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skynet_swiftTests.allTests),
    ]
}
#endif
