import XCTest

import MongoORMTests

var tests = [XCTestCaseEntry]()
tests += MongoORMTests.allTests()
XCTMain(tests)