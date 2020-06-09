import RxBlocking
import RxSwift
@testable import Teller
import XCTest

class PagingRepositoryDataSourceMockTest: XCTestCase {
    var dataSource: PagingRepositoryDataSourceMock<String, RepositoryRequirementsForTesting, PagingRepositoryRequirementsForTesting, String, Error, Void>!
    let defaultRequirements = RepositoryRequirementsForTesting()
    let defaultPagingRequirements = PagingRepositoryRequirementsForTesting(pageNumber: 1)

    override func setUp() {
        dataSource = PagingRepositoryDataSourceMock()
    }

    // MARK: - deleteCache

    func test_deleteCache_expectMockOnlyAfterSet() {
        XCTAssertFalse(dataSource.mockCalled)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_deleteCache_expectCalledOnlyAfterSet() {
        XCTAssertFalse(dataSource.deleteCacheCalled)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertTrue(dataSource.deleteCacheCalled)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertTrue(dataSource.deleteCacheCalled)
    }

    func test_deleteCache_expectCalledCountIncrementAfterSet() {
        XCTAssertEqual(dataSource.deleteCacheCallsCount, 0)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertEqual(dataSource.deleteCacheCallsCount, 1)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertEqual(dataSource.deleteCacheCallsCount, 2)
    }

    func test_deleteCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [RepositoryRequirementsForTesting] = [
            RepositoryRequirementsForTesting(foo: "first"),
            RepositoryRequirementsForTesting(foo: "second")
        ]
        let expectedInvocations = givenInvocations

        XCTAssertTrue(dataSource.deleteCacheInvocations.isEmpty)

        dataSource.deleteCache(givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.deleteCacheInvocations[0], expectedInvocations[0])

        dataSource.deleteCache(givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.deleteCacheInvocations[0], expectedInvocations[0])
        XCTAssertEqual(dataSource.deleteCacheInvocations[1], expectedInvocations[1])
    }

    func test_deleteCache_expectCallClosure() {
        var calledClosure = false
        dataSource.deleteCacheClosure = { requirements in
            XCTAssertEqual(self.defaultRequirements, requirements)

            calledClosure = true
        }

        XCTAssertFalse(calledClosure)

        dataSource.deleteCache(defaultRequirements)

        XCTAssertTrue(calledClosure)
    }

    // MARK: - persistOnlyFirstPage

    func test_persistOnlyFirstPage_expectMockOnlyAfterSet() {
        XCTAssertFalse(dataSource.mockCalled)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_persistOnlyFirstPage_expectCalledOnlyAfterSet() {
        XCTAssertFalse(dataSource.persistOnlyFirstPageCalled)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.persistOnlyFirstPageCalled)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertTrue(dataSource.persistOnlyFirstPageCalled)
    }

    func test_persistOnlyFirstPage_expectCalledCountIncrementAfterSet() {
        XCTAssertEqual(dataSource.persistOnlyFirstPageCallsCount, 0)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.persistOnlyFirstPageCallsCount, 1)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertEqual(dataSource.persistOnlyFirstPageCallsCount, 2)
    }

    func test_persistOnlyFirstPage_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [RepositoryRequirementsForTesting] = [
            RepositoryRequirementsForTesting(foo: "first"),
            RepositoryRequirementsForTesting(foo: "second")
        ]
        let expectedInvocations = givenInvocations

        XCTAssertTrue(dataSource.persistOnlyFirstPageInvocations.isEmpty)

        dataSource.persistOnlyFirstPage(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.persistOnlyFirstPageInvocations[0], expectedInvocations[0])

        dataSource.persistOnlyFirstPage(requirements: givenInvocations.removeFirst())

        XCTAssertEqual(dataSource.persistOnlyFirstPageInvocations[0], expectedInvocations[0])
        XCTAssertEqual(dataSource.persistOnlyFirstPageInvocations[1], expectedInvocations[1])
    }

    func test_persistOnlyFirstPage_expectCallClosure() {
        var calledClosure = false
        dataSource.persistOnlyFirstPageClosure = { requirements in
            XCTAssertEqual(self.defaultRequirements, requirements)

            calledClosure = true
        }

        XCTAssertFalse(calledClosure)

        dataSource.persistOnlyFirstPage(requirements: defaultRequirements)

        XCTAssertTrue(calledClosure)
    }

    // MARK: - getNextPagePagingRequirements

    func test_getNextPagePagingRequirements_expectMockOnlyAfterSet() {
        dataSource.getNextPagePagingRequirementsClosure = { currentPagingRequirements, _ in
            PagingRepositoryRequirementsForTesting(pageNumber: currentPagingRequirements.pageNumber + 1)
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: defaultPagingRequirements, nextPageRequirements: nil)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_getNextPagePagingRequirements_expectCalledOnlyAfterSet() {
        dataSource.getNextPagePagingRequirementsClosure = { currentPagingRequirements, _ in
            PagingRepositoryRequirementsForTesting(pageNumber: currentPagingRequirements.pageNumber + 1)
        }

        XCTAssertFalse(dataSource.getNextPagePagingRequirementsCalled)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: defaultPagingRequirements, nextPageRequirements: nil)

        XCTAssertTrue(dataSource.getNextPagePagingRequirementsCalled)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: defaultPagingRequirements, nextPageRequirements: nil)

        XCTAssertTrue(dataSource.getNextPagePagingRequirementsCalled)
    }

    func test_getNextPagePagingRequirements_expectCalledCountIncrementAfterSet() {
        dataSource.getNextPagePagingRequirementsClosure = { currentPagingRequirements, _ in
            PagingRepositoryRequirementsForTesting(pageNumber: currentPagingRequirements.pageNumber + 1)
        }

        XCTAssertEqual(dataSource.getNextPagePagingRequirementsCallsCount, 0)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: defaultPagingRequirements, nextPageRequirements: nil)

        XCTAssertEqual(dataSource.getNextPagePagingRequirementsCallsCount, 1)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: defaultPagingRequirements, nextPageRequirements: nil)

        XCTAssertEqual(dataSource.getNextPagePagingRequirementsCallsCount, 2)
    }

    func test_getNextPagePagingRequirements_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [PagingRepositoryRequirementsForTesting] = [
            PagingRepositoryRequirementsForTesting(pageNumber: 1),
            PagingRepositoryRequirementsForTesting(pageNumber: 2)
        ]
        let expectedInvocations = givenInvocations

        dataSource.getNextPagePagingRequirementsClosure = { currentPagingRequirements, _ in
            PagingRepositoryRequirementsForTesting(pageNumber: currentPagingRequirements.pageNumber + 1)
        }

        XCTAssertTrue(dataSource.getNextPagePagingRequirementsInvocations.isEmpty)

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: givenInvocations.removeFirst(), nextPageRequirements: nil)

        XCTAssertEqual(dataSource.getNextPagePagingRequirementsInvocations[0].0, expectedInvocations[0])

        _ = dataSource.getNextPagePagingRequirements(currentPagingRequirements: givenInvocations.removeFirst(), nextPageRequirements: nil)

        XCTAssertEqual(dataSource.getNextPagePagingRequirementsInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.getNextPagePagingRequirementsInvocations[1].0, expectedInvocations[1])
        XCTAssertNil(dataSource.getNextPagePagingRequirementsInvocations[0].1)
        XCTAssertNil(dataSource.getNextPagePagingRequirementsInvocations[1].1)
    }

    func test_getNextPagePagingRequirements_expectReturnsFromClosure() {
        dataSource.getNextPagePagingRequirementsClosure = { currentPagingRequirements, _ in
            PagingRepositoryRequirementsForTesting(pageNumber: currentPagingRequirements.pageNumber + 1)
        }

        let actualFirstResult = dataSource.getNextPagePagingRequirements(currentPagingRequirements: PagingRepositoryRequirementsForTesting(pageNumber: 1), nextPageRequirements: nil)
        XCTAssertEqual(actualFirstResult, PagingRepositoryRequirementsForTesting(pageNumber: 2))

        let actualSecondResult = dataSource.getNextPagePagingRequirements(currentPagingRequirements: PagingRepositoryRequirementsForTesting(pageNumber: 3), nextPageRequirements: nil)
        XCTAssertEqual(actualSecondResult, PagingRepositoryRequirementsForTesting(pageNumber: 4))
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

    // MARK: - automaticallyRefresh

    func test_automaticallyRefresh_expectReturnDefaultValueWhenCalled() {
        let expected = true
        let actual = dataSource.automaticallyRefresh

        XCTAssertEqual(expected, actual)
    }

    func test_automaticallyRefresh_expectMockOnlyAfterSet() {
        dataSource.automaticallyRefreshClosure = {
            true
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.automaticallyRefresh

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_automaticallyRefresh_expectCalledOnlyAfterSet() {
        dataSource.automaticallyRefreshClosure = {
            true
        }

        XCTAssertFalse(dataSource.automaticallyRefreshCalled)

        _ = dataSource.automaticallyRefresh

        XCTAssertTrue(dataSource.automaticallyRefreshCalled)

        _ = dataSource.automaticallyRefresh

        XCTAssertTrue(dataSource.automaticallyRefreshCalled)
    }

    func test_automaticallyRefresh_expectCalledCountIncrementAfterSet() {
        dataSource.automaticallyRefreshClosure = {
            true
        }

        XCTAssertEqual(dataSource.automaticallyRefreshCallsCount, 0)

        _ = dataSource.automaticallyRefresh

        XCTAssertEqual(dataSource.automaticallyRefreshCallsCount, 1)

        _ = dataSource.automaticallyRefresh

        XCTAssertEqual(dataSource.automaticallyRefreshCallsCount, 2)
    }

    func test_automaticallyRefresh_expectGetResultFromClosure() {
        var givenInvocations: [Bool] = [
            false,
            true
        ]
        let expectedInvocations = givenInvocations

        dataSource.automaticallyRefreshClosure = {
            givenInvocations.removeFirst()
        }

        let firstActualMaxAgeOfCache = dataSource.automaticallyRefresh
        let secondActualMaxAgeOfCache = dataSource.automaticallyRefresh

        XCTAssertEqual(firstActualMaxAgeOfCache, expectedInvocations[0])
        XCTAssertEqual(secondActualMaxAgeOfCache, expectedInvocations[1])
    }

    // MARK: - fetchFreshCache

    func test_fetchFreshCache_expectMockOnlyAfterSet() {
        dataSource.fetchFreshCacheClosure = { _, _ in
            Single.just(FetchResponse.success(PagedFetchResponse(areMorePages: true, nextPageRequirements: nil, fetchResponse: "")))
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_fetchFreshCache_expectCalledOnlyAfterSet() {
        dataSource.fetchFreshCacheClosure = { _, _ in
            Single.just(FetchResponse.success(PagedFetchResponse(areMorePages: true, nextPageRequirements: nil, fetchResponse: "")))
        }

        XCTAssertFalse(dataSource.fetchFreshCacheCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.fetchFreshCacheCalled)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.fetchFreshCacheCalled)
    }

    func test_fetchFreshCache_expectCalledCountIncrementAfterSet() {
        dataSource.fetchFreshCacheClosure = { _, _ in
            Single.just(FetchResponse.success(PagedFetchResponse(areMorePages: true, nextPageRequirements: nil, fetchResponse: "")))
        }

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 0)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 1)

        _ = dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.fetchFreshCacheCallsCount, 2)
    }

    func test_fetchFreshCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [(RepositoryRequirementsForTesting, PagingRepositoryRequirementsForTesting)] = [
            (RepositoryRequirementsForTesting(foo: "first"), PagingRepositoryRequirementsForTesting(pageNumber: 1)),
            (RepositoryRequirementsForTesting(foo: "second"), PagingRepositoryRequirementsForTesting(pageNumber: 2))
        ]
        let expectedInvocations = givenInvocations

        dataSource.fetchFreshCacheClosure = { _, _ in
            Single.just(FetchResponse.success(PagedFetchResponse(areMorePages: true, nextPageRequirements: nil, fetchResponse: "")))
        }

        XCTAssertTrue(dataSource.fetchFreshCacheInvocations.isEmpty)

        var next = givenInvocations.removeFirst()
        _ = dataSource.fetchFreshCache(requirements: next.0, pagingRequirements: next.1)

        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0].1, expectedInvocations[0].1)

        next = givenInvocations.removeFirst()
        _ = dataSource.fetchFreshCache(requirements: next.0, pagingRequirements: next.1)

        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[0].1, expectedInvocations[0].1)
        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[1].0, expectedInvocations[1].0)
        XCTAssertEqual(dataSource.fetchFreshCacheInvocations[1].1, expectedInvocations[1].1)
    }

    func test_fetchFreshCache_expectReturnsFromClosure() {
        var givenInvocations: [FetchResponse<PagedFetchResponse<String, Void>, Error>] = [
            FetchResponse.success(PagedFetchResponse(areMorePages: true, nextPageRequirements: nil, fetchResponse: "first")),
            FetchResponse.success(PagedFetchResponse(areMorePages: false, nextPageRequirements: nil, fetchResponse: "second"))
        ]
        let expectedInvocations = givenInvocations

        dataSource.fetchFreshCacheClosure = { _, _ in
            Single.just(givenInvocations.removeFirst())
        }

        let actualFirstResult = try! dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements).toBlocking().first()!.get()
        XCTAssertEqual(actualFirstResult.areMorePages, true)
        XCTAssertEqual(actualFirstResult.fetchResponse, "first")
        XCTAssertNil(actualFirstResult.nextPageRequirements)

        let actualSecondResult = try! dataSource.fetchFreshCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements).toBlocking().first()!.get()
        XCTAssertEqual(actualSecondResult.areMorePages, false)
        XCTAssertEqual(actualSecondResult.fetchResponse, "second")
        XCTAssertNil(actualSecondResult.nextPageRequirements)
    }

    // MARK: - saveCache

    func test_saveCache_expectMockOnlyAfterSet() {
        XCTAssertFalse(dataSource.mockCalled)

        try! dataSource.saveCache("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_saveCache_expectCalledOnlyAfterSet() {
        XCTAssertFalse(dataSource.saveCacheCalled)

        try! dataSource.saveCache("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.saveCacheCalled)

        try! dataSource.saveCache("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.saveCacheCalled)
    }

    func test_saveCache_expectCalledCountIncrementAfterSet() {
        XCTAssertEqual(dataSource.saveCacheCallsCount, 0)

        try! dataSource.saveCache("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.saveCacheCallsCount, 1)

        try! dataSource.saveCache("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.saveCacheCallsCount, 2)
    }

    func test_saveCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [(String, RepositoryRequirementsForTesting, PagingRepositoryRequirementsForTesting)] = [
            ("first-cache", RepositoryRequirementsForTesting(foo: "req1"), PagingRepositoryRequirementsForTesting(pageNumber: 1)),
            ("second-cache", RepositoryRequirementsForTesting(foo: "req2"), PagingRepositoryRequirementsForTesting(pageNumber: 2))
        ]
        let expectedInvocations = givenInvocations

        XCTAssertTrue(dataSource.saveCacheInvocations.isEmpty)

        var next = givenInvocations.removeFirst()
        try! dataSource.saveCache(next.0, requirements: next.1, pagingRequirements: next.2)

        XCTAssertEqual(dataSource.saveCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.saveCacheInvocations[0].1, expectedInvocations[0].1)
        XCTAssertEqual(dataSource.saveCacheInvocations[0].2, expectedInvocations[0].2)

        next = givenInvocations.removeFirst()
        try! dataSource.saveCache(next.0, requirements: next.1, pagingRequirements: next.2)

        XCTAssertEqual(dataSource.saveCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.saveCacheInvocations[1].0, expectedInvocations[1].0)
        XCTAssertEqual(dataSource.saveCacheInvocations[0].1, expectedInvocations[0].1)
        XCTAssertEqual(dataSource.saveCacheInvocations[1].1, expectedInvocations[1].1)
        XCTAssertEqual(dataSource.saveCacheInvocations[0].2, expectedInvocations[0].2)
        XCTAssertEqual(dataSource.saveCacheInvocations[1].2, expectedInvocations[1].2)
    }

    // MARK: - observeCache

    func test_observeCache_expectMockOnlyAfterSet() {
        dataSource.observeCacheClosure = { _, _ in
            Observable.just("")
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_observeCache_expectCalledOnlyAfterSet() {
        dataSource.observeCacheClosure = { _, _ in
            Observable.just("")
        }

        XCTAssertFalse(dataSource.observeCacheCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.observeCacheCalled)

        _ = dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.observeCacheCalled)
    }

    func test_observeCache_expectCalledCountIncrementAfterSet() {
        dataSource.observeCacheClosure = { _, _ in
            Observable.just("")
        }

        XCTAssertEqual(dataSource.observeCacheCallsCount, 0)

        _ = dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.observeCacheCallsCount, 1)

        _ = dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.observeCacheCallsCount, 2)
    }

    func test_observeCache_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [(RepositoryRequirementsForTesting, PagingRepositoryRequirementsForTesting)] = [
            (RepositoryRequirementsForTesting(foo: "first"), PagingRepositoryRequirementsForTesting(pageNumber: 1)),
            (RepositoryRequirementsForTesting(foo: "second"), PagingRepositoryRequirementsForTesting(pageNumber: 2))
        ]
        let expectedInvocations = givenInvocations

        dataSource.observeCacheClosure = { _, _ in
            Observable.just("")
        }

        XCTAssertTrue(dataSource.observeCacheInvocations.isEmpty)

        var next = givenInvocations.removeFirst()
        _ = dataSource.observeCache(requirements: next.0, pagingRequirements: next.1)

        XCTAssertEqual(dataSource.observeCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.observeCacheInvocations[0].1, expectedInvocations[0].1)

        next = givenInvocations.removeFirst()
        _ = dataSource.observeCache(requirements: next.0, pagingRequirements: next.1)

        XCTAssertEqual(dataSource.observeCacheInvocations[0].0, expectedInvocations[0].0)
        XCTAssertEqual(dataSource.observeCacheInvocations[0].1, expectedInvocations[0].1)
        XCTAssertEqual(dataSource.observeCacheInvocations[1].0, expectedInvocations[1].0)
        XCTAssertEqual(dataSource.observeCacheInvocations[1].1, expectedInvocations[1].1)
    }

    func test_observeCache_expectReturnsFromClosure() {
        var givenInvocations: [String] = [
            "first-cache",
            "second-cache"
        ]
        let expectedInvocations = givenInvocations

        dataSource.observeCacheClosure = { _, _ in
            Observable.just(givenInvocations.removeFirst())
        }

        let actualFirstResult = try! dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements).toBlocking().first()!
        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = try! dataSource.observeCache(requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements).toBlocking().first()!
        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }

    // MARK: - isCacheEmpty

    func test_isCacheEmpty_expectMockOnlyAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _, _ in
            true
        }

        XCTAssertFalse(dataSource.mockCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.mockCalled)
    }

    func test_isCacheEmpty_expectCalledOnlyAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _, _ in
            true
        }

        XCTAssertFalse(dataSource.isCacheEmptyCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.isCacheEmptyCalled)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertTrue(dataSource.isCacheEmptyCalled)
    }

    func test_isCacheEmpty_expectCalledCountIncrementAfterSet() {
        dataSource.isCacheEmptyClosure = { _, _, _ in
            true
        }

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 0)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 1)

        _ = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyCallsCount, 2)
    }

    func test_isCacheEmpty_expectInvocationsAppendsAfterSet() {
        var givenInvocations: [String] = [
            "first-cache",
            "second-cache"
        ]
        let expectedInvocations = givenInvocations

        dataSource.isCacheEmptyClosure = { _, _, _ in
            true
        }

        XCTAssertTrue(dataSource.isCacheEmptyInvocations.isEmpty)

        _ = dataSource.isCacheEmpty(givenInvocations.removeFirst(), requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].1, defaultRequirements)

        _ = dataSource.isCacheEmpty(givenInvocations.removeFirst(), requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)

        XCTAssertEqual(dataSource.isCacheEmptyInvocations[0].0, expectedInvocations[0])
        XCTAssertEqual(dataSource.isCacheEmptyInvocations[1].0, expectedInvocations[1])
    }

    func test_isCacheEmpty_expectReturnsFromClosure() {
        var givenInvocations: [Bool] = [
            true,
            false
        ]
        let expectedInvocations = givenInvocations

        dataSource.isCacheEmptyClosure = { _, _, _ in
            givenInvocations.removeFirst()
        }

        let actualFirstResult = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)
        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = dataSource.isCacheEmpty("", requirements: defaultRequirements, pagingRequirements: defaultPagingRequirements)
        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }
}
