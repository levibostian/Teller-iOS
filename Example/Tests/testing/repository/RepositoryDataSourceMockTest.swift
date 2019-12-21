import RxBlocking
import RxSwift
@testable import Teller
import XCTest

class RepositoryDataSourceMockTest: XCTestCase {
    var dataSource: RepositoryDataSourceMock<String, RepositoryRequirementsForTesting, String>!
    let defaultRequirements = RepositoryRequirementsForTesting()

    override func setUp() {
        dataSource = RepositoryDataSourceMock()
    }

    // MARK: - maxAgeOfCache

    func test_maxAgeOfCache_expectMockOnlyAfterSet() {
        dataSource.maxAgeOfCacheClosure = {
            Period(unit: 1, component: .day)
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.maxAgeOfCache

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_maxAgeOfCache_expectCalledOnlyAfterSet() {
        dataSource.maxAgeOfCacheClosure = {
            Period(unit: 1, component: .day)
        }

        XCTAssertFalse(dataSource.maxAgeOfCacheCalled)

        _ = dataSource.maxAgeOfCache

        XCTAssertTrue(dataSource.maxAgeOfCacheCalled)

        _ = dataSource.maxAgeOfCache

        XCTAssertTrue(dataSource.maxAgeOfCacheCalled)
    }

    func test_maxAgeOfCache_expectCalledCountIncrementAfterSet() {
        dataSource.maxAgeOfCacheClosure = {
            Period(unit: 1, component: .day)
        }

        XCTAssertEqual(dataSource.maxAgeOfCacheCallsCount, 0)

        _ = dataSource.maxAgeOfCache

        XCTAssertEqual(dataSource.maxAgeOfCacheCallsCount, 1)

        _ = dataSource.maxAgeOfCache

        XCTAssertEqual(dataSource.maxAgeOfCacheCallsCount, 2)
    }

    func test_maxAgeOfCache_expectGetResultFromClosure() {
        var givenInvocations: [Period] = [
            Period(unit: 1, component: .hour),
            Period(unit: 32, component: .day)
        ]
        let expectedInvocations = givenInvocations

        dataSource.maxAgeOfCacheClosure = {
            givenInvocations.removeFirst()
        }

        let firstActualMaxAgeOfCache = dataSource.maxAgeOfCache
        let secondActualMaxAgeOfCache = dataSource.maxAgeOfCache

        XCTAssertEqual(firstActualMaxAgeOfCache, expectedInvocations[0])
        XCTAssertEqual(secondActualMaxAgeOfCache, expectedInvocations[1])
    }

    // MARK: - fetchFreshCache

    func test_fetchFreshCache_expectMockOnlyAfterSet() {
        dataSource.fetchFreshCacheClosure = { _ in
            Single.just(FetchResponse.success(""))
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_fetchFreshCache_expectCalledOnlyAfterSet() {
        dataSource.fetchFreshCacheClosure = { _ in
            Single.just(FetchResponse.success(""))
        }

        XCTAssertFalse(dataSource.fetchFreshCacheCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.fetchFreshCacheCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.fetchFreshCacheCalled)
    }

    func test_fetchFreshCache_expectCalledCountIncrementAfterSet() {
        dataSource.fetchFreshCacheClosure = { _ in
            Single.just(FetchResponse.success(""))
        }

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 0)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 1)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 2)
    }

    func test_fetchFreshCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [RepositoryRequirementsForTesting] = [
            RepositoryRequirementsForTesting(foo: "first"),
            RepositoryRequirementsForTesting(foo: "second")
        ]
        let expectedInvocations = givenInvocations

        dataSource.fetchFreshCacheClosure = { _ in
            Single.just(FetchResponse.success(""))
        }

        XCTAssertTrue(dataSource.fetchFreshCacheInvocations.isEmpty)

        _ = dataSource.fetchFreshCache(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0], expectedInvocations[0])

        _ = dataSource.fetchFreshCache(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0], expectedInvocations[0])
        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[1], expectedInvocations[1])
    }

    func test_fetchFreshCache_expectReturnsFromClosure() {
        var givenInvocations: [FetchResponse<String>] = [
            FetchResponse.success("first"),
            FetchResponse.success("second")
        ]
        let expectedInvocations = givenInvocations

        dataSource.fetchFreshCacheClosure = { _ in
            Single.just(givenInvocations.removeFirst())
        }

        let actualFirstResult: FetchResponse<String> = try! dataSource.fetchFreshCache(requirements: defaultRequirements).toBlocking().first()!
        XCTAssertEqual(try actualFirstResult.get(), try expectedInvocations[0].get())

        let actualSecondResult: FetchResponse<String> = try! dataSource.fetchFreshCache(requirements: defaultRequirements).toBlocking().first()!
        XCTAssertEqual(try actualSecondResult.get(), try expectedInvocations[1].get())
    }

    // MARK: - saveCache

    func test_saveCache_expectMockOnlyAfterSet() {
        XCTAssertFalse(dataSource.mockCalled)

        try! dataSource.saveCache("cache", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_saveCache_expectCalledOnlyAfterSet() {
        XCTAssertFalse(dataSource.saveCacheCalled)

        try! dataSource.saveCache("cache", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.saveCacheCalled)

        try! dataSource.saveCache("cache", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.saveCacheCalled)
    }

    func test_saveCache_expectCalledCountIncrementAfterSet() {
        XCTAssertEqual(dataSource.saveCacheCallsCount, 0)

        try! dataSource.saveCache("cache", requirements: defaultRequirements)

        XCTAssertEqual(dataSource.saveCacheCallsCount, 1)

        try! dataSource.saveCache("cache", requirements: defaultRequirements)

        XCTAssertEqual(dataSource.saveCacheCallsCount, 2)
    }

    func test_saveCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [String] = [
            "first-cache",
            "second-cache"
        ]
        let expectedInvocations = givenInvocations

        XCTAssertTrue(dataSource.saveCacheInvocations.isEmpty)

        try! dataSource.saveCache(givenInvocations.removeFirst(), requirements: defaultRequirements)

        XCTAssertEqual(dataSource.saveCacheInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.saveCacheInvocations[0].1, defaultRequirements)

        try! dataSource.saveCache(givenInvocations.removeFirst(), requirements: defaultRequirements)

        XCTAssertEqual(dataSource.saveCacheInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.saveCacheInvocations[1].0, expectedInvocations[1])
    }

    // MARK: - observeCache

    func test_observeCache_expectMockOnlyAfterSet() {
        dataSource.observeCacheClosure = { _ in
            Observable.just("")
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_observeCache_expectCalledOnlyAfterSet() {
        dataSource.observeCacheClosure = { _ in
            Observable.just("")
        }

        XCTAssertFalse(dataSource.observeCacheCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.observeCacheCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.observeCacheCalled)
    }

    func test_observeCache_expectCalledCountIncrementAfterSet() {
        dataSource.observeCacheClosure = { _ in
            Observable.just("")
        }

        XCTAssertEqual(dataSource.observeCacheCallsCount, 0)

        _ = dataSource.observeCache(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.observeCacheCallsCount, 1)

        _ = dataSource.observeCache(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.observeCacheCallsCount, 2)
    }

    func test_observeCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [RepositoryRequirementsForTesting] = [
            RepositoryRequirementsForTesting(foo: "first"),
            RepositoryRequirementsForTesting(foo: "second")
        ]
        let expectedInvocations = givenInvocations

        dataSource.observeCacheClosure = { _ in
            Observable.just("")
        }

        XCTAssertTrue(dataSource.observeCacheInvocations.isEmpty)

        _ = dataSource.observeCache(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.observeCacheInvocations[0], expectedInvocations[0])

        _ = dataSource.observeCache(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.observeCacheInvocations[0], expectedInvocations[0])
        XCTAssertEqual(dataSource.observeCacheInvocations[1], expectedInvocations[1])
    }

    func test_observeCache_expectReturnsFromClosure() {
        var givenInvocations: [String] = [
            "first-cache",
            "second-cache"
        ]
        let expectedInvocations = givenInvocations

        dataSource.observeCacheClosure = { _ in
            Observable.just(givenInvocations.removeFirst())
        }

        let actualFirstResult: String = try! dataSource.observeCache(requirements: defaultRequirements).toBlocking().first()!
        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult: String = try! dataSource.observeCache(requirements: defaultRequirements).toBlocking().first()!
        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }

    // MARK: - isCacheEmpty

    func test_isCacheEmpty_expectMockOnlyAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _ in
            true
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_isCacheEmpty_expectCalledOnlyAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _ in
            true
        }

        XCTAssertFalse(dataSource.isCacheEmptyCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.isCacheEmptyCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements)

        XCTAssertTrue(dataSource.isCacheEmptyCalled)
    }

    func test_isCacheEmpty_expectCalledCountIncrementAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _ in
            true
        }

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 0)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 1)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 2)
    }

    func test_isCacheEmpty_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [String] = [
            "first-cache",
            "second-cache"
        ]
        let expectedInvocations = givenInvocations

        dataSource.isCacheEmptyClosure = { _, _ in
            true
        }

        XCTAssertTrue(dataSource.isCacheEmptyInvocations.isEmpty)

        _ = dataSource.isCacheEmpty(givenInvocations.removeFirst(), requirements: defaultRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].1, defaultRequirements)

        _ = dataSource.isCacheEmpty(givenInvocations.removeFirst(), requirements: defaultRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.isCacheEmptyInvocations[1].0, expectedInvocations[1])
    }

    func test_isCacheEmpty_expectReturnsFromClosure() {
        var givenInvocations: [Bool] = [
            true,
            false
        ]
        let expectedInvocations = givenInvocations

        dataSource.isCacheEmptyClosure = { _, _ in
            givenInvocations.removeFirst()
        }

        let actualFirstResult = dataSource.isCacheEmpty("", requirements: defaultRequirements)
        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = dataSource.isCacheEmpty("", requirements: defaultRequirements)
        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }
}
