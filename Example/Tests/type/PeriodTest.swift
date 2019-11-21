@testable import Teller
import XCTest

class PeriodTest: XCTestCase {
    private var period: Period!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_toDate() {
        period = Period(unit: 1, component: Calendar.Component.second)
        XCTAssertLessThan(period.toDate().timeIntervalSince1970, Date().timeIntervalSince1970)

        let lessThan = Period(unit: 2, component: Calendar.Component.second)
        let olderThan = Period(unit: 1, component: Calendar.Component.second)
        XCTAssertLessThan(lessThan.toDate().timeIntervalSince1970, olderThan.toDate().timeIntervalSince1970)
    }
}
