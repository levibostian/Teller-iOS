@testable import Teller
import XCTest

/**
 Note: It's not best practice to test 2 functions in the same unit test. In many of the test functions below, we are testing the `initState` and `initStateAsync` functions together in 1 function. That is because the testing for each of them is exactly the same. Both functions have logic inside that it's very important to test against both of the functions for the same behavior. Originally, the test function logic was split into 2 test functions but then you experience a lot of copy/paste. Not worth it.
 */
class RepositoryTestingTest: XCTestCase {
    private let defaultRequirements = RepositoryRequirementsForTesting(foo: "")
    private var dataSource: RepositoryDataSourceMock<String, RepositoryRequirementsForTesting, String>!
    private var repository: TellerRepository<RepositoryDataSourceMock<String, RepositoryRequirementsForTesting, String>>!
    private var syncStateManager: RepositorySyncStateManager!

    override func setUp() {
        resetTests()
    }

    private func resetTests() {
        dataSource = RepositoryDataSourceMock()
        repository = TellerRepository(dataSource: dataSource)
        syncStateManager = TellerRepositorySyncStateManager()

        Teller.shared.clear()
    }

    func test_initState_noCache_expectSetState() {
        let expectedSetValues = RepositoryTesting.SetValues(lastFetched: nil)

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            XCTAssertEqual(expectedSetValues, actualSetValues)

            let expectedLastFetched: Date? = nil
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)

            XCTAssertEqual(expectedLastFetched, actualLastFetched)

            XCTAssertFalse(dataSource.saveCacheCalled)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.noCache()
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.noCache()
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_cacheEmpty_expectSetState_expectDefaultLastFetchedTooOld() {
        let maxAgeOfCache = Period(unit: 1, component: .hour)

        func setupTest() {
            dataSource.maxAgeOfCacheClosure = { maxAgeOfCache }
        }
        setupTest()

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!
            XCTAssertNewer(actualLastFetched, maxAgeOfCache.toDate())
            XCTAssertEqualDate(actualSetValues.lastFetched!, actualLastFetched)

            XCTAssertFalse(dataSource.saveCacheCalled)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cacheEmpty()
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.cacheEmpty()
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_cache_expectSetState_expectDefaultLastFetchedTooOld() {
        let newCache = "cache"
        let maxAgeOfCache = Period(unit: 1, component: .hour)

        func setupTest() {
            dataSource.maxAgeOfCacheClosure = { maxAgeOfCache }
        }
        setupTest()

        func assertResult() {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!
            XCTAssertNewer(actualLastFetched, maxAgeOfCache.toDate())

            XCTAssertEqual(dataSource.saveCacheCallsCount, 1)
            XCTAssertEqual(dataSource.saveCacheInvocations[0].0, newCache)
        }

        _ = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cache(newCache)
        }

        assertResult()

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult()

            expectToComplete.fulfill()
        }) {
            $0.cache(newCache)
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_cache_expectGetSetValuesCorrectLastUpdated() {
        let maxAgeOfCache = Period(unit: 1, component: .hour)
        let newCache = "cache"

        func setupTest() {
            dataSource.maxAgeOfCacheClosure = { maxAgeOfCache }
        }
        setupTest()

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!

            XCTAssertEqualDate(actualSetValues.lastFetched!, actualLastFetched)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cache(newCache)
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.cache(newCache)
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_cacheTooOld_expectSetState() {
        let maxAgeOfCache = Period(unit: 1, component: .hour)

        func setupTest() {
            dataSource.maxAgeOfCacheClosure = { maxAgeOfCache }
        }
        setupTest()

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!
            // Too old of cache means: saved last fetched is older then max age of cache.
            XCTAssertOlder(actualLastFetched, maxAgeOfCache.toDate())
            XCTAssertEqualDate(actualSetValues.lastFetched!, actualLastFetched)

            XCTAssertFalse(dataSource.saveCacheCalled)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cacheEmpty {
                $0.cacheTooOld()
            }
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.cacheEmpty {
                $0.cacheTooOld()
            }
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_cacheNotTooOld_expectSetState() {
        let maxAgeOfCache = Period(unit: 1, component: .hour)

        func setupTest() {
            dataSource.maxAgeOfCacheClosure = { maxAgeOfCache }
        }
        setupTest()

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!
            // Not too old of cache means: saved last fetched is newer then max age of cache.
            XCTAssertNewer(actualLastFetched, maxAgeOfCache.toDate())
            XCTAssertEqualDate(actualSetValues.lastFetched!, actualLastFetched)

            XCTAssertFalse(dataSource.saveCacheCalled)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cacheEmpty {
                $0.cacheNotTooOld()
            }
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.cacheEmpty {
                $0.cacheNotTooOld()
            }
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_initState_setLastFetched_expectSetState() {
        let lastFetchedOneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!

        func setupTest() {}
        setupTest()

        func assertResult(actualSetValues: RepositoryTesting.SetValues) {
            let actualLastFetched = syncStateManager.lastTimeFetchedData(tag: defaultRequirements.tag)!
            XCTAssertEqualDate(actualLastFetched, lastFetchedOneMonthAgo)
            XCTAssertEqualDate(actualSetValues.lastFetched!, lastFetchedOneMonthAgo)

            XCTAssertFalse(dataSource.saveCacheCalled)
        }

        let actualSetValues = TellerRepository.testing.initState(repository: repository, requirements: defaultRequirements) {
            $0.cacheEmpty {
                $0.lastFetched(lastFetchedOneMonthAgo)
            }
        }

        assertResult(actualSetValues: actualSetValues)

        // async
        resetTests()
        setupTest()
        let expectToComplete = expectation(description: "Expect to complete")
        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { actualSetValues in
            assertResult(actualSetValues: actualSetValues)

            expectToComplete.fulfill()
        }) {
            $0.cacheEmpty {
                $0.lastFetched(lastFetchedOneMonthAgo)
            }
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    // MARK: - initStateAsync

    func test_initStateAsync_cache_expectSaveOffMainThread() {
        let newCache = "cache"
        let expectToComplete = expectation(description: "To complete")
        expectToComplete.expectedFulfillmentCount = 2

        dataSource.saveCacheClosure = { _, _ in
            XCTAssertFalse(Thread.isMainThread)

            expectToComplete.fulfill()
        }

        TellerRepository.testing.initStateAsync(repository: repository, requirements: defaultRequirements, onComplete: { setValues in
            expectToComplete.fulfill()
        }) {
            $0.cache(newCache)
        }
        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }
}
