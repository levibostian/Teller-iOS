import Foundation
@testable import Teller
import XCTest

class DataState_StateTest: XCTestCase {
    private var dataState: DataState<String>!
    let getDataRequirements: RepositoryRequirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /**
     It's important to test:

     1. Equatable protocols for each of the states.
     */
    func test_cacheState_cacheStateNone() {
        dataState = DataState<String>.none()
        XCTAssertNil(dataState.cacheState())
    }

    func test_cacheState_cacheEmpty() {
        let fetched = Date()
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: fetched).change().cacheIsEmpty()
        XCTAssertEqual(dataState.cacheState(), DataState.CacheState.cacheEmpty(fetched: fetched))
    }

    func test_cacheState_cacheData() {
        let data = "foo"
        let dataFetched = Date()
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: dataFetched).change().cachedData(data)
        XCTAssertEqual(dataState.cacheState(), DataState.CacheState.cacheData(data: data, fetched: dataFetched))
    }

    func test_cacheState_nil() {
        dataState = try! DataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch()
        XCTAssertNil(dataState.cacheState())
    }

    func test_noCacheState_cacheStateNone() {
        dataState = DataState<String>.none()
        XCTAssertNil(dataState.noCacheState())
    }

    func test_noCacheState_noCache() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertEqual(dataState.noCacheState(), DataState.NoCacheState.noCache)
    }

    func test_noCacheState_firstFetchOfData() {
        dataState = try! DataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch()
        XCTAssertEqual(dataState.noCacheState(), DataState.NoCacheState.firstFetchOfData)
    }

    func test_firstFetchState_finishedFirstFetchSuccessfully() {
        let timeFetched = Date()
        dataState = try! DataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch().change().successfulFirstFetch(timeFetched: timeFetched)
        XCTAssertEqual(dataState.noCacheState(), DataState.NoCacheState.finishedFirstFetchOfData(errorDuringFetch: nil))
    }

    func test_firstFetchState_errorFirstFetch() {
        let error = FetchError()
        dataState = try! DataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch().change().errorFirstFetch(error: error)
        XCTAssertEqual(dataState.noCacheState(), DataState.NoCacheState.finishedFirstFetchOfData(errorDuringFetch: error))
    }

    func test_firstFetchState_nil() {
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().cacheIsEmpty()
        XCTAssertNil(dataState.noCacheState())
    }

    func test_fetchingFreshDataState_cacheStateNone() {
        dataState = DataState<String>.none()
        XCTAssertNil(dataState.fetchingFreshDataState())
    }

    func test_fetchingFreshDataState_fetchingFreshData() {
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().fetchingFreshCache()
        XCTAssertEqual(dataState.fetchingFreshDataState(), DataState.FetchingFreshDataState.fetchingFreshCacheData)
    }

    func test_fetchingFreshDataState_finishedFetchingFreshData() {
        let error = FetchError()
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().fetchingFreshCache().change().failFetchingFreshCache(error)
        XCTAssertNil(dataState.fetchingFreshDataState())
    }

    func test_fetchingFreshDataState_nil() {
        dataState = try! DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().cacheIsEmpty()
        XCTAssertNil(dataState.fetchingFreshDataState())
    }

    class FetchError: Error {}
}
