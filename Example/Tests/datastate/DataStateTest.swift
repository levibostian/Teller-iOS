@testable import Teller
import XCTest

class DataStateTest: XCTestCase {
    private var dataState: DataState<String>!
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
        dataState = DataState.none()

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertNil(dataState.requirements)
        XCTAssertNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cast_expectSetPropertiesCorrectly() {
        dataState = DataState.none()
        let given = dataState

        let expectedNewCache: Double = 1
        let actual = dataState.convert { (oldCache) -> Double? in
            expectedNewCache
        }

        XCTAssertEqual(actual.cacheData, expectedNewCache)
        XCTAssertEqual(actual.noCacheExists, given?.noCacheExists)
        XCTAssertEqual(actual.fetchingForFirstTime, given?.fetchingForFirstTime)
        XCTAssertEqual(actual.lastTimeFetched, given?.lastTimeFetched)
        XCTAssertEqual(actual.isFetchingFreshData, given?.isFetchingFreshData)
        XCTAssertNil(actual.errorDuringFirstFetch)
        XCTAssertEqual(actual.justCompletedSuccessfulFirstFetch, given?.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(actual.errorDuringFetch)
        XCTAssertEqual(actual.justCompletedSuccessfullyFetchingFreshData, given?.justCompletedSuccessfullyFetchingFreshData)
    }
}
