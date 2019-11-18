@testable import Teller
import XCTest

class LocalDataStateTest: XCTestCase {
    private var dataState: LocalDataState<String>!

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }

    func testNone_setsPropertiesCorrectly() {
        dataState = LocalDataState.none()

        XCTAssertFalse(dataState.isEmpty)
        XCTAssertNil(dataState.data)
    }

    func testIsEmpty_setsPropertiesCorrectly() {
        dataState = LocalDataState.isEmpty()

        XCTAssertTrue(dataState.isEmpty)
        XCTAssertNil(dataState.data)
    }

    func testData_setsPropertiesCorrectly() {
        let data = "foo"
        dataState = LocalDataState.data(data: data)

        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
    }
}
