import Foundation
@testable import Teller
import XCTest

class DataState_StateTest: XCTestCase {
    let defaultRequirements: RepositoryRequirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

    // MARK: - No cache, equatable

    /**
     All of the given states:
     1. No cache
     2. No cache, fetching
     3. No cache, error during fetch
     4. Cache
     5. Cache empty
     6. Cache, just completed first fetch
     7. Cache, fetching
     8. Cache, successful fetch (not first)
     9. Cache not successful, error
     10. None (cannot test, it's a fatal)
     */

    // 1
    func test_state_givenNoCache_expectEqual() {
        let actual = CacheState<String>.testing.noCache(requirements: defaultRequirements).state

        switch actual {
        case .noCache: break
        case .cache: XCTFail("should be no cache")
        }
    }

    // 2
    func test_state_givenNoCacheFetching_expectEqual() {
        let actual = CacheState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.fetchingFirstTime()
        }.state

        switch actual {
        case .noCache: break
        case .cache: XCTFail("should be no cache")
        }
    }

    // 3
    func test_state_givenNoCacheErrorDuringFetch_expectEqual() {
        let fetchError = FetchError()

        let actual = CacheState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.failedFirstFetch(error: fetchError)
        }.state

        switch actual {
        case .noCache: break
        case .cache: XCTFail("should be no cache")
        }
    }

    // 4
    func test_state_givenCache_expectEqual() {
        let fetched = Date()
        let givenCache = "cache"

        let actual = CacheState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(givenCache)
        }.state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertEqual(cache, givenCache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    // 5
    func test_state_givenCacheEmpty_expectEqual() {
        let fetched = Date()

        let actual = CacheState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched).state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertNil(cache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    // 6
    func test_state_givenCacheJustCompletedFirstFetch_expectEqual() {
        let fetched = Date()

        let actual = CacheState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.successfulFirstFetch(timeFetched: fetched)
        }.state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertNil(cache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    // 7
    func test_state_givenCacheFetching_expectEqual() {
        let fetched = Date()
        let givenCache = "cache"

        let actual = CacheState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(givenCache)
            $0.fetching()
        }.state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertEqual(cache, givenCache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    // 8
    func test_state_givenCacheSuccessfulFetch_expectEqual() {
        let fetched = Date()
        let givenCache = "cache"

        let actual = CacheState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: Date()) {
            $0.cache(givenCache)
            $0.successfulFetch(timeFetched: fetched)
        }.state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertEqual(cache, givenCache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    // 9
    func test_state_givenCacheFailedFetch_expectEqual() {
        let fetched = Date()
        let givenCache = "cache"
        let fetchError = FetchError()

        let actual = CacheState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(givenCache)
            $0.failedFetch(error: fetchError)
        }.state

        switch actual {
        case .noCache: XCTFail("should be no cache")
        case .cache(let cache, let cacheAge):
            XCTAssertEqual(cache, givenCache)
            XCTAssertEqual(cacheAge, fetched)
        }
    }

    class FetchError: Error {}
}
