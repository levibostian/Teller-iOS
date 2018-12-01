//
//  OnlineDataStateStateMachineTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 11/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class OnlineDataStateStateMachineTest: XCTestCase {

    private var dataState: OnlineDataState<String>!
    let getDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

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
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_noCacheExists_travelingToNextNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)

        XCTAssertNoThrow(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try self.dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try self.dataState.change().cachedData(""))
        XCTAssertThrowsError(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cacheExists_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cacheExists_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_firstFetch_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try self.dataState.change().firstFetch())
    }

    func test_firstFetch_setsCorrectProperties() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertTrue(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_firstFetch_travelingToNextNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()

        XCTAssertNoThrow(try self.dataState.change().firstFetch())
        XCTAssertNoThrow(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertNoThrow(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try self.dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try self.dataState.change().cachedData(""))
        XCTAssertThrowsError(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_errorFirstFetch_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))

        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
    }

    func test_errorFirstFetch_setsCorrectProperties() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()
        let fetchFail: Error = Failure()
        self.dataState = try! self.dataState.change().errorFirstFetch(error: fetchFail)

        XCTAssertTrue(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertNil(dataState.lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: dataState.errorDuringFirstFetch, rhs: fetchFail))
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_errorFirstFetch_travelingToNextNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()
        self.dataState = try! self.dataState.change().errorFirstFetch(error: Failure())

        XCTAssertNoThrow(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertThrowsError(try self.dataState.change().cacheIsEmpty())
        XCTAssertThrowsError(try self.dataState.change().cachedData(""))
        XCTAssertThrowsError(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFirstFetch_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))

        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
    }

    func test_successfulFirstFetch_setsCorrectProperties() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()
        let lastTimeFetched = Date()
        self.dataState = try! self.dataState.change().successfulFirstFetch(timeFetched: lastTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertTrue(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_successfulFirstFetch_travelingToNextNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        self.dataState = try! self.dataState.change().firstFetch()
        self.dataState = try! self.dataState.change().successfulFirstFetch(timeFetched: Date())

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cacheIsEmpty_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().cacheIsEmpty())
    }

    func test_cacheIsEmpty_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        self.dataState = try! self.dataState.change().cacheIsEmpty()

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertNil(dataState.cacheData)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cacheIsEmpty_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().cacheIsEmpty()

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_cachedData_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().cachedData("cache"))
    }

    func test_cachedData_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        let cache = "cache"
        self.dataState = try! self.dataState.change().cachedData(cache)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_cachedData_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        self.dataState = try! self.dataState.change().cachedData(cache)

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_fetchingFreshCache_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().fetchingFreshCache())
    }

    func test_fetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        self.dataState = try! self.dataState.change().cachedData(cache)
        self.dataState = try! self.dataState.change().fetchingFreshCache()

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_fetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().fetchingFreshCache()

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertNoThrow(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_failFetchingFreshCache_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().failFetchingFreshCache(Failure()))

        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try self.dataState.change().failFetchingFreshCache(Failure()))
    }

    func test_failFetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        self.dataState = try! self.dataState.change().cachedData(cache)
        let fetchFailure = Failure()
        self.dataState = try! self.dataState.change().failFetchingFreshCache(fetchFailure)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, lastTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: dataState.errorDuringFetch, rhs: fetchFailure))
        XCTAssertFalse(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_failFetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        self.dataState = try! self.dataState.change().failFetchingFreshCache(Failure())

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFetchingFreshCache_errorCannotTravelToNode() {
        self.dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))

        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    func test_successfulFetchingFreshCache_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        let cache = "cache"
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        self.dataState = try! self.dataState.change().cachedData(cache)
        let newTimeFetched = Date()
        self.dataState = try! self.dataState.change().successfulFetchingFreshCache(timeFetched: newTimeFetched)

        XCTAssertFalse(dataState.noCacheExists)
        XCTAssertFalse(dataState.fetchingForFirstTime)
        XCTAssertEqual(dataState.cacheData, cache)
        XCTAssertEqual(dataState.lastTimeFetched, newTimeFetched)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertEqual(dataState.requirements! as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
        XCTAssertNotNil(dataState.stateMachine)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.justCompletedSuccessfulFirstFetch)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertTrue(dataState.justCompletedSuccessfullyFetchingFreshData)
    }

    func test_successfulFetchingFreshCache_travelingToNextNode() {
        let lastTimeFetched = Date()
        self.dataState = OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: lastTimeFetched)
        self.dataState = try! self.dataState.change().fetchingFreshCache()
        self.dataState = try! self.dataState.change().successfulFetchingFreshCache(timeFetched: Date())

        XCTAssertThrowsError(try self.dataState.change().firstFetch())
        XCTAssertThrowsError(try self.dataState.change().errorFirstFetch(error: Failure()))
        XCTAssertThrowsError(try self.dataState.change().successfulFirstFetch(timeFetched: Date()))
        XCTAssertNoThrow(try self.dataState.change().cacheIsEmpty())
        XCTAssertNoThrow(try self.dataState.change().cachedData(""))
        XCTAssertNoThrow(try self.dataState.change().fetchingFreshCache())
        XCTAssertThrowsError(try self.dataState.change().successfulFetchingFreshCache(timeFetched: Date()))
    }

    class Failure: Error {
    }

}
