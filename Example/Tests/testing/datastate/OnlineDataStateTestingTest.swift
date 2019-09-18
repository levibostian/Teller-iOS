//
//  OnlineCacheStateTestingTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

enum ErrorForTesting: Error {
    case foo
}

class OnlineDataStateTestingTest: XCTestCase {

    var requirements: ReposRepositoryGetDataRequirements!

    override func setUp() {
        requirements = ReposRepositoryGetDataRequirements(username: "")
    }

    func test_none_expectResultToEqualStateMachine() {
        let fromStateMachine: OnlineDataState<String> = OnlineDataState.none()
        let testing: OnlineDataState<String> = OnlineDataStateTesting.none()

        XCTAssertEqual(fromStateMachine, testing)
    }

    // MARK - noCache

    func test_noCache_expectResultToEqualStateMachine() {
        let fromStateMachine = OnlineDataStateStateMachine<String>.noCacheExists(requirements: requirements)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.noCache(requirements: requirements)

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_fetching_expectResultToEqualStateMachine() {
        let fromStateMachine = try! OnlineDataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch()
        let testing: OnlineDataState<String> = OnlineDataStateTesting.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_failFetching_expectResultToEqualStateMachine() {
        let error = ErrorForTesting.foo

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch().change()
            .errorFirstFetch(error: error)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.noCache(requirements: requirements) {
            $0.failedFirstFetch(error: error)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_successfulFirstFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch().change()
            .successfulFirstFetch(timeFetched: timeFetched)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.noCache(requirements: requirements) {
            $0.successfulFirstFetch(timeFetched: timeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    // MARK - cache, empty

    func test_cache_cacheEmpty_notGivingCache_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty()
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched)

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_fetching_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache()
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.fetching()
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_failedFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let failedFetch = ErrorForTesting.foo

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache().change()
            .failFetchingFreshCache(failedFetch)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.failedFetch(error: failedFetch)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_successfulFetch_expectResultToEqualStateMachine() {
        let timeInThePast = Date(timeIntervalSinceNow: -3000)
        let newTimeFetched = Date()

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeInThePast).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache().change()
            .successfulFetchingFreshCache(timeFetched: newTimeFetched)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeInThePast) {
            $0.successfulFetch(timeFetched: newTimeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    // MARK - cache, cache not empty

    func test_cache_cacheNotEmpty_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache: cache)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_fetching_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"
        
        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache).change()
            .fetchingFreshCache()
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache: cache)
            $0.fetching()
        }
        
        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_failedFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"
        let fetchFail = ErrorForTesting.foo

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache).change()
            .fetchingFreshCache().change()
            .failFetchingFreshCache(fetchFail)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache: cache)
            $0.failedFetch(error: fetchFail)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_successfulFetch_expectResultToEqualStateMachine() {
        let timeInThePast = Date(timeIntervalSinceNow: -3000)
        let newTimeFetched = Date()
        let cache = "cache"

        let fromStateMachine = try! OnlineDataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeInThePast).change()
            .cachedData(cache).change()
            .fetchingFreshCache().change()
            .successfulFetchingFreshCache(timeFetched: newTimeFetched)
        let testing: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: timeInThePast) {
            $0.cache(cache: cache)
            $0.successfulFetch(timeFetched: newTimeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

}
