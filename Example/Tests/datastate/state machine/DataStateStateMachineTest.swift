@testable import Teller
import XCTest

class DataStateStateMachineTest: XCTestCase {
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

    /**
     The tests below follow the pattern below for all of the functions of the state machine:

     1. errorCannotTravelToNode - Testing various states of the state machine going into the function under test that will cause an error.
     2. _setsCorrectProperties - After a successful transition to the state machine node under test, the properties in the returned onlinedatastate are set correctly.
     3. _travelingToNextNode - Going from the state machine node under test to all of the other possible nodes, what paths are valid and not valid?
     */
    func test_noCacheExists_setsCorrectProperties() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_noCacheExists_travelingToNextNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)

        XCTAssertNoThrow(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try dataState.change().cachedData(""))
        XCTAssertThrowsError(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cacheExists_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cacheExists_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_firstFetch_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try dataState.change().firstFetch())
    }

    func test_firstFetch_setsCorrectProperties() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertTrue(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_firstFetch_travelingToNextNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()

        XCTAssertNoThrow(try dataState.change().firstFetch())
        XCTAssertNoThrow(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertNoThrow(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try dataState.change().cachedData(""))
        XCTAssertThrowsError(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_errorFirstFetch_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))

        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
    }

    func test_errorFirstFetch_setsCorrectProperties() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()
        let fetchFail: Error = Failure()
        dataState = try! dataState.change().errorFirstFetch(error: fetchFail)

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: dataState.errorDuringFirstFetch, rhs: fetchFail))
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_errorFirstFetch_travelingToNextNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()
        dataState = try! dataState.change().errorFirstFetch(error: Failure())

        XCTAssertNoThrow(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try dataState.change().cachedData(""))
        XCTAssertThrowsError(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFirstFetch_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))

        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
    }

    func test_successfulFirstFetch_setsCorrectProperties() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()
        let lastTimeFetched = Date()
        dataState = try! dataState.change().successfulFirstFetch(timeFetched: lastTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertTrue(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_successfulFirstFetch_travelingToNextNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        dataState = try! dataState.change().firstFetch()
        dataState = try! dataState.change().successfulFirstFetch(timeFetched: Date())

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cacheIsEmpty_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().cacheIsEmpty())
    }

    func test_cacheIsEmpty_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().fetchingFreshCache()
        dataState = try! dataState.change().cacheIsEmpty()

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cacheIsEmpty_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().cacheIsEmpty()

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cachedData_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().cachedData("cache"))
    }

    func test_cachedData_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().fetchingFreshCache()
        let cache = "cache"
        dataState = try! dataState.change().cachedData(cache)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cachedData_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        dataState = try! dataState.change().cachedData(cache)

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_fetchingFreshCache_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().fetchingFreshCache())
    }

    func test_fetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        dataState = try! dataState.change().cachedData(cache)
        dataState = try! dataState.change().fetchingFreshCache()

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_fetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().fetchingFreshCache()

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertNoThrow(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_failFetchingFreshCache_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().failFetchingFreshCache(Failure()))

        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try dataState.change().failFetchingFreshCache(Failure()))
    }

    func test_failFetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        dataState = try! dataState.change().fetchingFreshCache()
        dataState = try! dataState.change().cachedData(cache)
        let fetchFailure = Failure()
        dataState = try! dataState.change().failFetchingFreshCache(fetchFailure)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: dataState.errorDuringFetch, rhs: fetchFailure))
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_failFetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().fetchingFreshCache()
        dataState = try! dataState.change().failFetchingFreshCache(Failure())

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFetchingFreshCache_errorCannotTravelToNode() {
        dataState = DataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))

        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        dataState = try! dataState.change().fetchingFreshCache()
        dataState = try! dataState.change().cachedData(cache)
        let newTimeFetched = Date()
        dataState = try! dataState.change().successfulFetchingFreshCache(timeFetched: newTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, newTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertTrue(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_successfulFetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        dataState = DataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        dataState = try! dataState.change().fetchingFreshCache()
        dataState = try! dataState.change().successfulFetchingFreshCache(timeFetched: Date())

        XCTAssertThrowsError(try dataState.change().firstFetch())
        XCTAssertThrowsError(try dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try dataState.change().cachedData(""))
        XCTAssertNoThrow(try dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    class Failure: Error {}
}
