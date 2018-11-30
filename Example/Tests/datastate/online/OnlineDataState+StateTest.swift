//
//  OnlineDataState+StateTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class OnlineDataState_StateTest: XCTestCase {
    
    private var dataState: OnlineDataState<String>!
    let getDataRequirements: OnlineRepositoryGetDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
    
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
    func test_cacheState_cacheEmpty() {
        let fetched = Date()
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: fetched).change().cacheIsEmpty()
        XCTAssertEqual(dataState.cacheState(), OnlineDataState.CacheState.cacheEmpty(fetched: fetched))
    }
    
    func test_cacheState_cacheData() {
        let data = "foo"
        let dataFetched = Date()
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: dataFetched).change().cachedData(data)
        XCTAssertEqual(dataState.cacheState(), OnlineDataState.CacheState.cacheData(data: data, fetched: dataFetched))
    }

    func test_cacheState_nil() {
        dataState = try! OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch()
        XCTAssertNil(dataState.cacheState())
    }

    func test_noCacheState_noCache() {
        dataState = OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements)
        XCTAssertEqual(dataState.noCacheState(), OnlineDataState.NoCacheState.noCache)
    }

    func test_noCacheState_firstFetchOfData() {
        dataState = try! OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch()
        XCTAssertEqual(dataState.noCacheState(), OnlineDataState.NoCacheState.firstFetchOfData)
    }

    func test_firstFetchState_finishedFirstFetchSuccessfully() {
        let timeFetched = Date()
        dataState = try! OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch().change().successfulFirstFetch(timeFetched: timeFetched)
        XCTAssertEqual(dataState.noCacheState(), OnlineDataState.NoCacheState.finishedFirstFetchOfData(errorDuringFetch: nil))
    }

    func test_firstFetchState_errorFirstFetch() {
        let error = FetchError()
        dataState = try! OnlineDataStateStateMachine.noCacheExists(requirements: getDataRequirements).change().firstFetch().change().errorFirstFetch(error: error)
        XCTAssertEqual(dataState.noCacheState(), OnlineDataState.NoCacheState.finishedFirstFetchOfData(errorDuringFetch: error))
    }

    func test_firstFetchState_nil() {
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().cacheIsEmpty()
        XCTAssertNil(dataState.noCacheState())
    }

    func test_fetchingFreshDataState_fetchingFreshData() {
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().fetchingFreshCache()
        XCTAssertEqual(dataState.fetchingFreshDataState(), OnlineDataState.FetchingFreshDataState.fetchingFreshCacheData)
    }

    func test_fetchingFreshDataState_finishedFetchingFreshData() {
        let error = FetchError()
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().fetchingFreshCache().change().failFetchingFreshCache(error)
        XCTAssertNil(dataState.fetchingFreshDataState())
    }

    func test_fetchingFreshDataState_nil() {
        dataState = try! OnlineDataStateStateMachine.cacheExists(requirements: getDataRequirements, lastTimeFetched: Date()).change().cacheIsEmpty()
        XCTAssertNil(dataState.fetchingFreshDataState())
    }

    class FetchError: Error {
    }
    
}
