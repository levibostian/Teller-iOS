@testable import Teller
import XCTest

class DataStateTest: XCTestCase {
    private var dataState: CacheState<String>!
    let getDataRequirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_none_setsCorrectProperties() {
        dataState = CacheState.none()

        XCTAssertTrue(dataState.cacheExists)
        XCTAssertNil(dataState.cache)
        XCTAssertNil(dataState.cacheAge)
        XCTAssertFalse(dataState.isRefreshing)
        XCTAssertNil(dataState.requirements)
        XCTAssertNil(dataState.stateMachine)
        XCTAssertFalse(dataState.justFinishedSuccessfulRefresh)
        XCTAssertNil(dataState.refreshError)
    }

    func test_cast_expectSetPropertiesCorrectly() {
        dataState = CacheState.none()
        let given = dataState

        let expectedNewCache: Double = 1
        let actual = dataState.convert { (oldCache) -> Double? in
            expectedNewCache
        }

        XCTAssertEqual(actual.cache, expectedNewCache)
        XCTAssertEqual(actual.cacheExists, given?.cacheExists)
        XCTAssertEqual(actual.cacheAge, given?.cacheAge)
        XCTAssertEqual(actual.isRefreshing, given?.isRefreshing)
        XCTAssertEqual(actual.justFinishedSuccessfulRefresh, given?.justFinishedSuccessfulRefresh)
        XCTAssertNil(actual.refreshError)
    }
}
