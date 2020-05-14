import RxSwift
import RxTest
@testable import Teller
import XCTest

class PagingRepositoryTest: XCTestCase {
    private var repository: TellerPagingRepository<MockPagingRepositoryDataSource>!
    private var dataSource: MockPagingRepositoryDataSource!
    private var syncStateManager: MockRepositorySyncStateManager!
    private var refreshManager: RepositoryRefreshManager!

    private var compositeDisposable: CompositeDisposable!

    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()

        TellerUserDefaultsUtil.shared.clear()

        refreshManager = AppRepositoryRefreshManager()
        initDataSource(fakeData: getDataSourceFakeData())
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData())
        initRepository()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        compositeDisposable.dispose()
        compositeDisposable = nil
    }

    private func getDataSourceFakeData(isDataEmpty: Bool = false, observeCachedData: Observable<String> = Observable.empty(), fetchFreshData: Single<FetchResponse<PagedFetchResponse<String, Void>, Error>> = Single.never(), automaticallyRefresh: Bool = true) -> MockPagingRepositoryDataSource.FakeData {
        return MockPagingRepositoryDataSource.FakeData(automaticallyRefresh: automaticallyRefresh, isDataEmpty: isDataEmpty, observeCachedData: observeCachedData, fetchFreshData: fetchFreshData)
    }

    private func getSyncStateManagerFakeData(isDataTooOld: Bool = false, hasEverFetchedData: Bool = false, lastTimeFetchedData: Date? = nil) -> MockRepositorySyncStateManager.FakeData {
        return MockRepositorySyncStateManager.FakeData(isDataTooOld: isDataTooOld, hasEverFetchedData: hasEverFetchedData, lastTimeFetchedData: lastTimeFetchedData)
    }

    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initDataSource(fakeData: MockPagingRepositoryDataSource.FakeData, maxAgeOfCache: Period = Period(unit: 1, component: Calendar.Component.second)) {
        dataSource = MockPagingRepositoryDataSource(fakeData: fakeData, maxAgeOfCache: maxAgeOfCache)
    }

    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initSyncStateManager(syncStateManagerFakeData: MockRepositorySyncStateManager.FakeData) {
        syncStateManager = MockRepositorySyncStateManager(fakeData: syncStateManagerFakeData)
    }

    private func initRepository() {
        repository = TellerPagingRepository(firstPageRequirements: MockPagingRepositoryDataSource.MockPagingRequirements(), dataSource: dataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: refreshManager) // Use AppSchedulersProvider to test on read multi-threading. Bugs in Teller have been missed from using a single threaded environment.
    }

    func test_pagingRequirements_givenSetRequirementsAlready_expectPerformAutomaticFetch() {
        // We want to test that the paging repository forces automatic refreshes
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()

        // Order matters in this test. We are testing both ways.
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)

        XCTAssertEqual(dataSource.fetchFreshDataCount, 1)
    }

    func test_pagingRequirements_givenNotYetSetRequirements_expectPerformAutomaticFetchAfterSetRequirements() {
        // We want to test that the paging repository forces automatic refreshes
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()

        // Order matters in this test. We are testing both ways.
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        XCTAssertEqual(dataSource.fetchFreshDataCount, 1)
    }

    // Because Teller only checks if the cache is too old for the first page of the cache, we need to force Teller to refresh for all pages > page 1, even if the data is not too old.
    func test_pagingRequirements_givenDataNotTooOld_givenSetNewPagingRequirements_expectPerformAutomaticFetchAfterSetRequirements() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 3)

        XCTAssertEqual(dataSource.fetchFreshDataCount, 2) // 2 times because we are setting a new paging requirement twice that is not the first page.
    }

    func test_pagingRequirements_givenSetOnlyFirstPageOfData_expectNoFetch() {
        // We want to test that the paging repository forces automatic refreshes
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()

        XCTAssertEqual(dataSource.fetchFreshDataCount, 0)
    }

    /**
     Testing refresh. Mostly testing when the data source is told to delete all data except the first page of cache.

     With these tests, there are many scenarios when the data source is told to delete old cache.
     * When setting requirements and we are observing the first page.
     * Force refresh
     * After refresh complete and observing first page again.

      The tests below may use AssertGreaterThan or equivalent not exact assertions. This is because some scenarios are difficult to determine the exact number of times the data source is called because of async operations. The tests should be setup in a way that tests one thing and one thing only to prevent testing too many scenarios at once. Example: setup tests so that the data source is not supposed to be called at all and then tweak things little by little and you may use AssertGreatThenOrEqual calls to see that something changed.
     */

    /**
     Baseline scenarios when the data state should not be told to persist only the first pages of cache.
     */
    func test_refresh_givenNoRefresh_givenNotFirstPage_givenCacheNotTooOld_expectDoNotOnlyPersistFirstPageOfData() {
        let refresh: ReplaySubject<FetchResponse<PagedFetchResponse<String, Void>, Error>> = ReplaySubject.createUnbounded()
        refresh.onNext(FetchResponse.success(PagedFetchResponse(areMorePages: false, nextPageRequirements: Void(), fetchResponse: "")))
        refresh.onCompleted()

        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.never(), fetchFreshData: refresh.asSingle(), automaticallyRefresh: true))
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        _ = try! repository.refresh(force: false)
            .toBlocking()
            .first()!

        XCTAssertEqual(dataSource.persistOnlyFirstPageCount, 0)
    }

    func test_refresh_givenNoRefresh_givenNotFirstPage_givenCacheTooOld_expectDoNotOnlyPersistFirstPageOfData() {
        let refresh: ReplaySubject<FetchResponse<PagedFetchResponse<String, Void>, Error>> = ReplaySubject.createUnbounded()
        refresh.onNext(FetchResponse.success(PagedFetchResponse(areMorePages: false, nextPageRequirements: Void(), fetchResponse: "")))
        refresh.onCompleted()

        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.never(), fetchFreshData: refresh.asSingle(), automaticallyRefresh: true))
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        _ = try! repository.refresh(force: false)
            .toBlocking()
            .first()!

        XCTAssertEqual(dataSource.persistOnlyFirstPageCount, 0)
    }

    func test_refresh_givenForceRefresh_expectForceRefreshPersistsOnlyFirstPageCache() {
        let refresh: ReplaySubject<FetchResponse<PagedFetchResponse<String, Void>, Error>> = ReplaySubject.createUnbounded()
        refresh.onNext(FetchResponse.success(PagedFetchResponse(areMorePages: false, nextPageRequirements: Void(), fetchResponse: "")))
        refresh.onCompleted()

        // Check to make sure save called on background thread.
        dataSource.persistOnlyFirstPageThen = {
            XCTAssertFalse(Thread.isMainThread)
        }

        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.never(), fetchFreshData: refresh.asSingle(), automaticallyRefresh: true))
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        _ = try! repository.refresh(force: true)
            .toBlocking()
            .first()!

        XCTAssertGreaterThanOrEqual(dataSource.persistOnlyFirstPageCount, 1)
    }

    func test_refresh_givenNoForceRefresh_givenObserveFirstPage_expectOnlyPersistFirstPageOfData() {
        let refresh: ReplaySubject<FetchResponse<PagedFetchResponse<String, Void>, Error>> = ReplaySubject.createUnbounded()
        refresh.onNext(FetchResponse.success(PagedFetchResponse(areMorePages: false, nextPageRequirements: Void(), fetchResponse: "")))
        refresh.onCompleted()

        let existingCache = "existing cache"

        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache), fetchFreshData: refresh.asSingle(), automaticallyRefresh: true))
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository()
        // We are setting the first page as requirements which will delete old cache.
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        let expectToGetCache = expectation(description: "Expect to get cache")

        compositeDisposable += repository.observe()
            .subscribe(onNext: { dataState in
                if dataState.cache?.cache == existingCache {
                    expectToGetCache.fulfill()
                }
            })

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)

        XCTAssertGreaterThanOrEqual(dataSource.persistOnlyFirstPageCount, 1)
    }

    func test_observe_givenFirstPageOfCache_expectTellDelegateToPersistOnlyFirstPage() {
        let observe = ReplaySubject<String>.createUnbounded()
        observe.onNext("first")

        // Check to make sure save called on background thread.
        dataSource.persistOnlyFirstPageThen = {
            XCTAssertFalse(Thread.isMainThread)
        }

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observe.asObservable()))
        initRepository()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements()
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        let expectObserveCache = expectation(description: "Expect to observe cache")

        compositeDisposable += repository.observe()
            .subscribe(onNext: { dataState in
                if dataState.cache?.cache == "first" {
                    expectObserveCache.fulfill()
                }
            })

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)

        XCTAssertEqual(dataSource.persistOnlyFirstPageCount, 1)
    }

    func test_observe_notGivenFirstPageOfCache_expectDoNotTellDelegateToPersistOnlyFirstPage() {
        let observe = ReplaySubject<String>.createUnbounded()
        observe.onNext("first")

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observe.asObservable()))
        initRepository()
        repository.pagingRequirements = MockPagingRepositoryDataSource.PagingRequirements(pageNumber: 2)
        repository.requirements = MockPagingRepositoryDataSource.Requirements(randomString: nil)

        let expectObserveCache = expectation(description: "Expect to observe cache")

        compositeDisposable += repository.observe()
            .subscribe(onNext: { dataState in
                if dataState.cache?.cache == "first" {
                    expectObserveCache.fulfill()
                }
            })

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)

        XCTAssertEqual(dataSource.persistOnlyFirstPageCount, 0)
    }

    /**
     We need to test deinit to make sure that we don't mess up super's ability to deinit.
     */
    func test_deinit_cancelExistingRefreshStopObserving() {
        let existingCache = "existing cache"
        let existingCacheFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: existingCacheFetched))
        let observeCache: Observable<String> = Observable.create { $0.onNext(existingCache)
            return Disposables.create()
        } // Make an Observable that does not complete on it's own like: Observable.just() to test that `deinit` completes for us.
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCache, fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockPagingRepositoryDataSource.MockRequirements(randomString: nil)

        let expectToBeginObserving = expectation(description: "Expect to begin observing cache")
        let expectToComplete = expectation(description: "Expect to complete observing of cache")
        let expectToDisposeObservingCache = expectation(description: "Expect to dispose observing of cache")

        compositeDisposable += repository.observe()
            .do(onNext: { state in
            }, onCompleted: {
                expectToComplete.fulfill()
            }, onSubscribe: {
                expectToBeginObserving.fulfill()
            }, onDispose: {
                expectToDisposeObservingCache.fulfill()
            })
            .subscribe()

        wait(for: [expectToBeginObserving], timeout: TestConstants.AWAIT_DURATION)

        let expectCancelledRefreshResult = expectation(description: "Expect to receive cancelled sync result")
        let expectRefreshToBegin = expectation(description: "Expect refresh to begin")
        let expectRefreshToDispose = expectation(description: "Expect refresh to dispose")
        compositeDisposable += try! repository.refresh(force: true)
            .do(onSuccess: { refreshResult in
                if refreshResult == .skipped(reason: .cancelled) {
                    expectCancelledRefreshResult.fulfill()
                }
            }, onSubscribe: {
                expectRefreshToBegin.fulfill()
            }, onDispose: {
                expectRefreshToDispose.fulfill()
            })
            .subscribe()

        wait(for: [expectRefreshToBegin], timeout: TestConstants.AWAIT_DURATION)

        repository = nil

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    private class Fail: Error {}
}
