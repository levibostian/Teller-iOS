@testable import Teller
import XCTest

enum ErrorForTesting: Error {
    case foo
}

class DataStateTestingTest: XCTestCase {
    var requirements: ReposRepositoryRequirements!

    override func setUp() {
        requirements = ReposRepositoryRequirements(username: "")
    }

    // MARK: - noCache

    func test_noCache_expectResultToEqualStateMachine() {
        let fromStateMachine = DataStateStateMachine<String>.noCacheExists(requirements: requirements)
        let testing: CacheState<String> = CacheStateTesting.noCache(requirements: requirements)

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_fetching_expectResultToEqualStateMachine() {
        let fromStateMachine = try! DataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch()
        let testing: CacheState<String> = CacheStateTesting.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_failFetching_expectResultToEqualStateMachine() {
        let error = ErrorForTesting.foo

        let fromStateMachine = try! DataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch().change()
            .errorFirstFetch(error: error)
        let testing: CacheState<String> = CacheStateTesting.noCache(requirements: requirements) {
            $0.failedFirstFetch(error: error)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_noCache_successfulFirstFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! DataStateStateMachine<String>.noCacheExists(requirements: requirements).change()
            .firstFetch().change()
            .successfulFirstFetch(timeFetched: timeFetched)
        let testing: CacheState<String> = CacheStateTesting.noCache(requirements: requirements) {
            $0.successfulFirstFetch(timeFetched: timeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    // MARK: - cache, empty

    func test_cache_cacheEmpty_notGivingCache_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty()
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched)

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_fetching_expectResultToEqualStateMachine() {
        let timeFetched = Date()

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache()
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.fetching()
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_failedFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let failedFetch = ErrorForTesting.foo

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache().change()
            .failFetchingFreshCache(failedFetch)
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.failedFetch(error: failedFetch)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheEmpty_successfulFetch_expectResultToEqualStateMachine() {
        let timeInThePast = Date(timeIntervalSinceNow: -3000)
        let newTimeFetched = Date()

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeInThePast).change()
            .cacheIsEmpty().change()
            .fetchingFreshCache().change()
            .successfulFetchingFreshCache(timeFetched: newTimeFetched)
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeInThePast) {
            $0.successfulFetch(timeFetched: newTimeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    // MARK: - cache, cache not empty

    func test_cache_cacheNotEmpty_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache)
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_fetching_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache).change()
            .fetchingFreshCache()
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache)
            $0.fetching()
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_failedFetch_expectResultToEqualStateMachine() {
        let timeFetched = Date()
        let cache = "cache"
        let fetchFail = ErrorForTesting.foo

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
            .cachedData(cache).change()
            .fetchingFreshCache().change()
            .failFetchingFreshCache(fetchFail)
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeFetched) {
            $0.cache(cache)
            $0.failedFetch(error: fetchFail)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }

    func test_cache_cacheNotEmpty_successfulFetch_expectResultToEqualStateMachine() {
        let timeInThePast = Date(timeIntervalSinceNow: -3000)
        let newTimeFetched = Date()
        let cache = "cache"

        let fromStateMachine = try! DataStateStateMachine<String>.cacheExists(requirements: requirements, lastTimeFetched: timeInThePast).change()
            .cachedData(cache).change()
            .fetchingFreshCache().change()
            .successfulFetchingFreshCache(timeFetched: newTimeFetched)
        let testing: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: timeInThePast) {
            $0.cache(cache)
            $0.successfulFetch(timeFetched: newTimeFetched)
        }

        XCTAssertEqual(fromStateMachine, testing)
    }
}
