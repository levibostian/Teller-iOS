import Foundation
@testable import Teller
import XCTest

class CacheStateMachineTest: XCTestCase {
    private var stateMachine: CacheStateMachine<String>!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_cacheEmpty_setsCorrectProperties() {
        stateMachine = CacheStateMachine.cacheEmpty()

        XCTAssertEqual(stateMachine.state, CacheStateMachine.State.cacheEmpty)
        XCTAssertNil(stateMachine.cache)
    }

    func test_cacheExists_setsCorrectProperties() {
        let cache = "cache"
        stateMachine = CacheStateMachine.cacheExists(cache)

        XCTAssertEqual(stateMachine.state, CacheStateMachine.State.cacheNotEmpty)
        XCTAssertEqual(stateMachine.cache, cache)
    }
}
