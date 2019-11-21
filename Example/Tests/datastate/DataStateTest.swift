@testable import Teller
import XCTest

class DataStateTest: XCTestCase {
    private var dataState: DataState<String>!
    let getDataRequirements = MockRepositoryDataSource.MockGetDataRequirements(randomString: nil)

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
}
