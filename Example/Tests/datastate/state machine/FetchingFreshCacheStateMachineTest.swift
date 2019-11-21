import Foundation
@testable import Teller
import XCTest

class FetchingFreshCacheStateMachineTest: XCTestCase {
    private var stateMachine: FetchingFreshCacheStateMachine!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_notFetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched)

        XCTAssertEqual(stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertNil(stateMachine.errorDuringFetch)
        XCTAssertEqual(stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_fetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching()

        XCTAssertEqual(stateMachine.state, FetchingFreshCacheStateMachine.State.isFetching)
        XCTAssertNil(stateMachine.errorDuringFetch)
        XCTAssertEqual(stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_failedFetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        let fail = Failure()
        stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching().failedFetching(fail)

        XCTAssertEqual(stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: stateMachine.errorDuringFetch, rhs: fail))
        XCTAssertEqual(stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_successfulFetch_setsCorrectProperties() {
        let lastTimeFetched = Date()
        let newTimeFetched = Date(timeIntervalSince1970: lastTimeFetched.timeIntervalSince1970 + 1)
        stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching().successfulFetch(timeFetched: newTimeFetched)

        XCTAssertEqual(stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertNil(stateMachine.errorDuringFetch)
        XCTAssertEqual(stateMachine.lastTimeFetched, newTimeFetched)
    }

    class Failure: Error {}
}
