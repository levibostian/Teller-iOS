import Foundation
@testable import Teller
import XCTest

class NoCacheStateMachineTest: XCTestCase {
    private var stateMachine: NoCacheStateMachine!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_noCacheExists_setsCorrectProperties() {
        stateMachine = NoCacheStateMachine.noCacheExists()

        XCTAssertEqual(stateMachine.state, NoCacheStateMachine.State.noCacheExists)
        XCTAssertNil(stateMachine.errorDuringFetch)
    }

    func test_fetching_setsCorrectProperties() {
        stateMachine = NoCacheStateMachine.noCacheExists().fetching()

        XCTAssertEqual(stateMachine.state, NoCacheStateMachine.State.isFetching)
        XCTAssertNil(stateMachine.errorDuringFetch)
    }

    func test_failedFetching_setsCorrectProperties() {
        let fail = Failure()
        stateMachine = NoCacheStateMachine.noCacheExists().fetching().failedFetching(error: fail)

        XCTAssertEqual(stateMachine.state, NoCacheStateMachine.State.noCacheExists)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: stateMachine.errorDuringFetch, rhs: fail))
    }

    class Failure: Error {}
}
