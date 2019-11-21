@testable import Teller
import XCTest

class TellerTest: XCTestCase {
    private var userDefaultsUtilMock: UserDefaultsUtilMock!
    private var teller: Teller!

    override func setUp() {
        super.setUp()

        userDefaultsUtilMock = UserDefaultsUtilMock()
        teller = Teller(userDefaultsUtil: userDefaultsUtilMock)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_clear_deletesAllData() {
        teller.clear()

        XCTAssertTrue(userDefaultsUtilMock.invokedClear)
        XCTAssertEqual(userDefaultsUtilMock.invokedClearCount, 1)
    }
}
