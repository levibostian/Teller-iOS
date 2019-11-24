import Foundation
@testable import Teller
import XCTest

class DataState_StateTest: XCTestCase {
    let defaultRequirements: RepositoryRequirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

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
     10. None
     */

    // 1
    func test_state_givenNoCache_expectEqual() {
        let expectedState = DataState<String>.State.noCache(fetching: false, errorDuringFetch: nil)
        let actual = DataState<String>.testing.noCache(requirements: defaultRequirements).state()

        XCTAssertEqual(expectedState, actual)
    }

    // 2
    func test_state_givenNoCacheFetching_expectEqual() {
        let expectedState = DataState<String>.State.noCache(fetching: true, errorDuringFetch: nil)
        let actual = DataState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.fetchingFirstTime()
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 3
    func test_state_givenNoCacheErrorDuringFetch_expectEqual() {
        let fetchError = FetchError()

        let expectedState = DataState<String>.State.noCache(fetching: false, errorDuringFetch: fetchError)
        let actual = DataState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.failedFirstFetch(error: fetchError)
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 4
    func test_state_givenCache_expectEqual() {
        let fetched = Date()
        let cache = "cache"

        let expectedState = DataState<String>.State.cache(cache: cache, lastFetched: fetched, firstCache: false, fetching: false, successfulFetch: false, errorDuringFetch: nil)
        let actual = DataState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(cache)
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 5
    func test_state_givenCacheEmpty_expectEqual() {
        let fetched = Date()

        let expectedState = DataState<String>.State.cache(cache: nil, lastFetched: fetched, firstCache: false, fetching: false, successfulFetch: false, errorDuringFetch: nil)
        let actual = DataState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched).state()

        XCTAssertEqual(expectedState, actual)
    }

    // 6
    func test_state_givenCacheJustCompletedFirstFetch_expectEqual() {
        let fetched = Date()

        let expectedState = DataState<String>.State.cache(cache: nil, lastFetched: fetched, firstCache: true, fetching: false, successfulFetch: false, errorDuringFetch: nil)
        let actual = DataState<String>.testing.noCache(requirements: defaultRequirements) {
            $0.successfulFirstFetch(timeFetched: fetched)
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 7
    func test_state_givenCacheFetching_expectEqual() {
        let fetched = Date()
        let cache = "cache"

        let expectedState = DataState<String>.State.cache(cache: cache, lastFetched: fetched, firstCache: false, fetching: true, successfulFetch: false, errorDuringFetch: nil)
        let actual = DataState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(cache)
            $0.fetching()
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 8
    func test_state_givenCacheSuccessfulFetch_expectEqual() {
        let fetched = Date()
        let cache = "cache"

        let expectedState = DataState<String>.State.cache(cache: cache, lastFetched: fetched, firstCache: false, fetching: false, successfulFetch: true, errorDuringFetch: nil)
        let actual = DataState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: Date()) {
            $0.cache(cache)
            $0.successfulFetch(timeFetched: fetched)
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 9
    func test_state_givenCacheFailedFetch_expectEqual() {
        let fetched = Date()
        let cache = "cache"
        let fetchError = FetchError()

        let expectedState = DataState<String>.State.cache(cache: cache, lastFetched: fetched, firstCache: false, fetching: false, successfulFetch: false, errorDuringFetch: fetchError)
        let actual = DataState<String>.testing.cache(requirements: defaultRequirements, lastTimeFetched: fetched) {
            $0.cache(cache)
            $0.failedFetch(error: fetchError)
        }.state()

        XCTAssertEqual(expectedState, actual)
    }

    // 10
    func test_state_givenNone_expectEqual() {
        let expectedState = DataState<String>.State.none
        let actual = DataState<String>.testing.none().state()

        XCTAssertEqual(expectedState, actual)
    }

    class FetchError: Error {}
}
