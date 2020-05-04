import RxSwift
import RxTest
@testable import Teller
import XCTest

/**
 You will notice a lot of expectation statements here. That is because the Repository and RepositoryRefreshManager use different threads for some processes. This makes this code run async and we need to use expectations to wait for some threads to be done and come back for results.
 Some tests are run sync because I mock the threads to using the current one. However, testing using real threads is good for these tests as bugs have been spotted when using different threads.

 Note: The way to write these tests is to use expectations instead of RxTest Recorded event assertions. Assertions used to be used, but tests were flaky. Here is an example test that is flaky:

 ```
 refresh()
 .do(onDispose: {
    expectation.fulfill() <--- Expectation fulfilled here indicates that the observer has "completed".
 })
 .subscribe()
 .observe(observer)

 wait(for: [expectation])

 AssertRecordedEvents(observer.events, [Recorded.next(), Recorded.complete()]) <--- Sometimes this test fails even though the expectation fulfilled. Sometimes it would pass.
 ```

 So because of the flakiness, we use expectations instead. If an event does *not* happen, the `wait()` statement will fail which results in the failed test. This method of testing that events come in 1 by 1 is more code, but not flaky.
 */
class RepositoryTest: XCTestCase {
    private var repository: TellerRepository<MockRepositoryDataSource>!
    private var dataSource: MockRepositoryDataSource!
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

    private func getFirstFetchEvent() -> DataState<String> {
        return try! DataStateStateMachine
            .noCacheExists(requirements: repository.requirements!).change()
            .firstFetch()
    }

    private func getCacheEmptyEvent(lastTimeFetched: Date) -> DataState<String> {
        return try! DataStateStateMachine
            .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .cacheIsEmpty()
    }

    private func getErrorFirstFetchEvent(_ error: Error) -> DataState<String> {
        return try! DataStateStateMachine
            .noCacheExists(requirements: repository.requirements!).change()
            .firstFetch().change()
            .errorFirstFetch(error: error)
    }

    private func getCacheDataEvent(lastTimeFetched: Date, cachedData: String) -> DataState<String> {
        return try! DataStateStateMachine
            .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .cachedData(cachedData)
    }

    private func getCacheExistsNotRefreshingEvent(lastTimeFetched: Date) -> DataState<String> {
        return DataStateStateMachine<String>
            .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeFetched)
    }

    private func getCacheDoesNotExistNotFetchingEvent() -> DataState<String> {
        return DataStateStateMachine<String>
            .noCacheExists(requirements: repository.requirements!)
    }

    private func getCacheExistsRefreshingEvent(lastTimeFetched: Date) -> DataState<String> {
        return try! DataStateStateMachine<String>
            .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .fetchingFreshCache()
    }

    private func getDataSourceFakeData(isDataEmpty: Bool = false, observeCachedData: Observable<String> = Observable.empty(), fetchFreshData: Single<FetchResponse<String, Error>> = Single.never(), automaticallyRefresh: Bool = true) -> MockRepositoryDataSource.FakeData {
        return MockRepositoryDataSource.FakeData(automaticallyRefresh: automaticallyRefresh, isDataEmpty: isDataEmpty, observeCachedData: observeCachedData, fetchFreshData: fetchFreshData)
    }

    private func getSyncStateManagerFakeData(isDataTooOld: Bool = false, hasEverFetchedData: Bool = false, lastTimeFetchedData: Date? = nil) -> MockRepositorySyncStateManager.FakeData {
        return MockRepositorySyncStateManager.FakeData(isDataTooOld: isDataTooOld, hasEverFetchedData: hasEverFetchedData, lastTimeFetchedData: lastTimeFetchedData)
    }

    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initDataSource(fakeData: MockRepositoryDataSource.FakeData, maxAgeOfCache: Period = Period(unit: 1, component: Calendar.Component.second)) {
        dataSource = MockRepositoryDataSource(fakeData: fakeData, maxAgeOfCache: maxAgeOfCache)
    }

    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initSyncStateManager(syncStateManagerFakeData: MockRepositorySyncStateManager.FakeData) {
        syncStateManager = MockRepositorySyncStateManager(fakeData: syncStateManagerFakeData)
    }

    private func initRepository() {
        repository = TellerRepository(dataSource: dataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: refreshManager) // Use AppSchedulersProvider to test on read multi-threading. Bugs in Teller have been missed from using a single threaded environment.
    }

    func test_refresh_requirementsNotSet_throwError() {
        initRepository()
        repository.requirements = nil

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        XCTAssertThrowsError(try repository.refresh(force: true).asObservable().subscribe(observer).dispose())
    }

    func test_refreshIfNoCache_requirementsNotSet_throwError() {
        initRepository()
        repository.requirements = nil

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        XCTAssertThrowsError(try repository.refreshIfNoCache().asObservable().subscribe(observer).dispose())
    }

    func test_dataSourceGetObservableCacheData_calledOnMainThread() {
        let expectToGetObservable = expectation(description: "Expect to get observable to observe cached data")
        expectToGetObservable.expectedFulfillmentCount = 1 // 1. When setting requirements, Repository begins observing cache. 2. Refresh call when observing cache in Repository. 3. Refresh call when setting requirements.
        expectToGetObservable.assertForOverFulfill = false // It might be fullfilled 3 times, or 2 times. This is hard to fix at this time until the test API for mocking it improved.

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false))

        DispatchQueue.global(qos: .background).async {
            XCTAssertFalse(Thread.isMainThread)

            self.dataSource.observeCacheDataThenAnswer = { requirements in
                XCTAssertTrue(Thread.isMainThread)
                expectToGetObservable.fulfill()

                return Observable.just("")
            }

            // Test when begin to observe cache on background thread
            self.initRepository()
            self.repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)
        }

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_deinit_cancelExistingRefreshStopObserving() {
        let existingCache = "existing cache"
        let existingCacheFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: existingCacheFetched))
        let observeCache: Observable<String> = Observable.create { $0.onNext(existingCache)
            return Disposables.create()
        } // Make an Observable that does not complete on it's own like: Observable.just() to test that `deinit` completes for us.
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCache, fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectToBeginObserving = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToComplete = expectation(description: "Expect to complete observing of cache")
        let expectToDisposeObservingCache = expectation(description: "Expect to dispose observing of cache")

        let existingCacheEvent = getCacheDataEvent(lastTimeFetched: existingCacheFetched, cachedData: existingCache)

        compositeDisposable += repository.observe()
            .do(onNext: { state in
                if state == existingCacheEvent {
                    expectToReceiveExistingCache.fulfill()
                }
            }, onCompleted: {
                expectToComplete.fulfill()
            }, onSubscribe: {
                expectToBeginObserving.fulfill()
            }, onDispose: {
                expectToDisposeObservingCache.fulfill()
            })
            .subscribe()

        wait(for: [expectToBeginObserving, expectToReceiveExistingCache], timeout: TestConstants.AWAIT_DURATION)

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

    func test_setNewRequirements_refreshGetsCancelled() {
        let mockRefreshManager = MockRepositoryRefreshManager()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        refreshManager = mockRefreshManager

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        // We expect the repository has only been initialized thus far. It has not changed the requirements yet.
        XCTAssertNil(repository.requirements)
        XCTAssertEqual(mockRefreshManager.invokedCancelRefreshCount, 0)

        // Set requirements for first time starts the first refresh
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        // We have not yet cancelled the previous request because the requirements has been only nil thus far.
        XCTAssertEqual(mockRefreshManager.invokedCancelRefreshCount, 0)

        wait(for: [expectRefreshToBegin], timeout: TestConstants.AWAIT_DURATION)

        // Set requirements for second time will cancel the previous refresh call
        repository.requirements = nil

        XCTAssertEqual(mockRefreshManager.invokedCancelRefreshCount, 1)
    }

    func test_setRequirementsNil_observeNoneStateOfData() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let existingCache = "existing cache"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache), fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectToBeginObservingCache = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToReceiveNoneDataState = expectation(description: "Expect to receive none data state")
        let expectToNotDispose = expectation(description: "Expect to not stop observing")
        expectToNotDispose.isInverted = true
        compositeDisposable += repository.observe()
            .do(onNext: { state in
                if state.cacheData == existingCache {
                    expectToReceiveExistingCache.fulfill()
                }
                if state == DataState.none() {
                    expectToReceiveNoneDataState.fulfill()
                }
            }, onSubscribe: {
                expectToBeginObservingCache.fulfill()
            }, onDispose: {
                expectToNotDispose.fulfill()
            })
            .subscribe()

        wait(for: [expectToBeginObservingCache, expectToReceiveExistingCache], timeout: TestConstants.AWAIT_DURATION)

        // This will cancel observing existing cache and go to none state.
        repository.requirements = nil

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_setRequirementsNilThenNotNil_continueToObserveSequence() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let existingCache = "existing cache"
        let newCache = "new cache"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.create { $0.onNext(existingCache)
            return Disposables.create()
        }, fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectToBeginObservingCache = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToReceiveNewCache = expectation(description: "Expect to receive new cache")
        let expectToReceiveNoneDataState = expectation(description: "Expect to receive none data state")
        let expectToNotDispose = expectation(description: "Expect to not stop observing")
        expectToNotDispose.isInverted = true
        compositeDisposable += repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { state in
                if state.cacheData == existingCache {
                    expectToReceiveExistingCache.fulfill()
                }
                if state.cacheData == newCache {
                    expectToReceiveNewCache.fulfill()
                }
                if state == DataState.none() {
                    expectToReceiveNoneDataState.fulfill()
                }
            }, onSubscribe: {
                expectToBeginObservingCache.fulfill()
            }, onDispose: {
                expectToNotDispose.fulfill()
            })
            .subscribe()

        wait(for: [expectToBeginObservingCache, expectToReceiveExistingCache], timeout: TestConstants.AWAIT_DURATION)

        // This will cancel observing existing cache and go to none state.
        repository.requirements = nil

        wait(for: [expectToReceiveNoneDataState], timeout: TestConstants.AWAIT_DURATION)

        dataSource.fakeData.observeCachedData = Observable.create { $0.onNext(newCache)
            return Disposables.create()
        }
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_saveCacheDataIsCalledOnBackgroundThread() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let fetchedData = "new cache"

        let expectDataSourceToSaveFetchedResponse = expectation(description: "Wait for data source saveData to be called.")

        dataSource.saveDataThen = { newCache in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(newCache, fetchedData)

            expectDataSourceToSaveFetchedResponse.fulfill()
        }

        syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            true
        }
        fetchFreshDataSubject.onNext(FetchResponse.success(fetchedData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_neverFetchedData_setRequirements_refreshGetsTriggered() {
        let mockRefreshManager = MockRepositoryRefreshManager()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        refreshManager = mockRefreshManager

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        // Set requirements for first time starts the first refresh
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        wait(for: [expectRefreshToBegin], timeout: TestConstants.AWAIT_DURATION)
    }

    func test_givenAutomaticallyRefreshFalse_setRequirements_refreshDoesNotGetTriggered() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(automaticallyRefresh: false))
        initRepository()

        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        XCTAssertEqual(dataSource.fetchFreshDataCount, 0)
    }

    func test_givenAutomaticallyRefreshFalse_observe_refreshDoesNotGetTriggered() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(automaticallyRefresh: false))
        initRepository()

        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        _ = try! repository.observe()
            .toBlocking()
            .first()

        XCTAssertEqual(dataSource.fetchFreshDataCount, 0)
    }

    func test_givenAutomaticallyRefreshFalse_existingCacheUpdate_refreshDoesNotGetTriggered() {
        let existingCache = "existing cache"
        let observeCachedData = Observable.just(existingCache)
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(observeCachedData: observeCachedData, automaticallyRefresh: false))
        initRepository()

        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        _ = try! repository.observe()
            .filter { $0.cacheData == existingCache }
            .toBlocking()
            .first()

        XCTAssertEqual(dataSource.fetchFreshDataCount, 0)
    }

    func test_cacheExistsButIsTooOld_setRequirementsBeginsFetch() {
        let mockRefreshManager = MockRepositoryRefreshManager()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        refreshManager = mockRefreshManager

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()

        // Set requirements for first time starts the first refresh
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cacheExistsButIsTooOld_observeNewCacheAfterSuccessfulFetch() {
        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        let newlyFetchedCache = "new cache"

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        let observeCacheDataObservable = BehaviorSubject<String>.init(value: existingCache)
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheDataObservable, fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        let expectStartObserving = expectation(description: "Expect observe to start observing cache")
        let expectToReceiveOldCache = expectation(description: "Expect to observe old cache data")
        expectToReceiveOldCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectToReceiveNewCache = expectation(description: "Expect to observe new cache data")
        expectToReceiveNewCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose and continue observing")
        expectObserveToNotDispose.isInverted = true

        compositeDisposable += repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { state in
                if state.cacheData == existingCache {
                    expectToReceiveOldCache.fulfill()
                }
                if state.cacheData == newlyFetchedCache {
                    expectToReceiveNewCache.fulfill()
                }
            }, onSubscribe: {
                expectStartObserving.fulfill()
            }, onDispose: {
                expectObserveToNotDispose.fulfill()
            })
            .subscribe()

        // Set requirements for first time starts the first refresh
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        wait(for: [expectStartObserving, expectToReceiveOldCache], timeout: TestConstants.AWAIT_DURATION)

        dataSource.saveDataThen = { newCache in
            observeCacheDataObservable.on(.next(newCache))
        }
        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.success(newlyFetchedCache))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_canObserveWithoutSettingRequirements() {
        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache), fetchFreshData: Single.never()))
        initRepository()
        // do not set requirements on the repository, yet.

        let expectStartObserving = expectation(description: "Expect observe to start observing cache")
        let expectToReceiveANoneStateFirst = expectation(description: "Expect to receive a none state first")
        let expectToReceiveOldCache = expectation(description: "Expect to observe old cache data")
        expectToReceiveOldCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose and continue observing")
        expectObserveToNotDispose.isInverted = true

        compositeDisposable += repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { state in
                if state == DataState.none() {
                    expectToReceiveANoneStateFirst.fulfill()
                }
                if state.cacheData == existingCache {
                    expectToReceiveOldCache.fulfill()
                }
            }, onSubscribe: {
                expectStartObserving.fulfill()
            }, onDispose: {
                expectObserveToNotDispose.fulfill()
            })
            .subscribe()

        wait(for: [expectStartObserving, expectToReceiveANoneStateFirst], timeout: TestConstants.AWAIT_DURATION)

        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cacheExistsNotTooOld_skipRefresh() {
        let mockRefreshManager = MockRepositoryRefreshManager()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToNotBegin = expectation(description: "Expect refresh to not begin.")
        expectRefreshToNotBegin.isInverted = true

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToNotBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        refreshManager = mockRefreshManager

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        // Trigger observe to test fetch does not happen here as well.
        compositeDisposable += repository.observe().subscribe()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_forceRefreshStartsRefreshEvenIfDataNotTooOld() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let fetchFreshData = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: fetchFreshData.asSingle()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")
        let expectRefreshToBeSuccessful = expectation(description: "Expect refresh to be successful")
        compositeDisposable += try! repository.refresh(force: true)
            .do(onSuccess: { refreshResult in
                if refreshResult == .successful {
                    expectRefreshToBeSuccessful.fulfill()
                }
            }, onSubscribe: {
                expectRefreshToBegin.fulfill()
            })
            .subscribe()

        fetchFreshData.onNext(FetchResponse<String, Error>.success("new data"))
        fetchFreshData.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_refresh_dataNotTooOld_skipsRefresh() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")
        let expectRefreshToBeSkipped = expectation(description: "Expect refresh to be skipped")
        compositeDisposable += try! repository.refresh(force: false)
            .do(onSuccess: { refreshResult in
                if refreshResult == .skipped(reason: .dataNotTooOld) {
                    expectRefreshToBeSkipped.fulfill()
                }
            }, onSubscribe: {
                expectRefreshToBegin.fulfill()
            })
            .subscribe()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    // when Repository.refresh() called and completed, you should be guaranteed that all operations are complete for the refresh, including saving of the cache.
    func test_refresh_expectAllOperationsDoneWhenRefreshComplete() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let fetchFreshData = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: fetchFreshData.asSingle()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let newlyFetchedData = "new data"
        let expectRefreshComplete = expectation(description: "Expect refresh to end.")
        compositeDisposable += try! repository.refresh(force: true)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // make sure refresh called on background to fully test this works as teller switches threads
            .do(onSuccess: { refreshResult in
                // expect new cache to be saved
                XCTAssertEqual(self.dataSource.saveDataCount, 1)
                XCTAssertEqual(self.dataSource.saveDataFetchedData!, newlyFetchedData)

                // expect sync state to be updated
                XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 1)

                expectRefreshComplete.fulfill()
            }, onSubscribe: {
                XCTAssertEqual(self.dataSource.saveDataCount, 0)
                XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 0)
            })
            .subscribe()

        fetchFreshData.onNext(FetchResponse<String, Error>.success(newlyFetchedData))
        fetchFreshData.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_failedFirstFetchDoesNotBeginObservingCache() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        let firstFetchFail = Fail()

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectObserveToBegin = expectation(description: "Expect observe() to begin observing")
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose")
        expectObserveToNotDispose.isInverted = true
        let expectObserveToReceiveNoneStateOrFirstFetch = expectation(description: "Expect observe to receive none state and first fetch")
        expectObserveToReceiveNoneStateOrFirstFetch.assertForOverFulfill = false
        let expectObserveToNotReceiveOtherEvents = expectation(description: "Expect observe to not receive any other events")
        expectObserveToNotReceiveOtherEvents.isInverted = true
        compositeDisposable += repository.observe()
            .do(onNext: { state in
                if state == self.getFirstFetchEvent() ||
                    state == DataState.none() ||
                    state == self.getErrorFirstFetchEvent(firstFetchFail) ||
                    state == self.getCacheDoesNotExistNotFetchingEvent() {
                    expectObserveToReceiveNoneStateOrFirstFetch.fulfill()
                } else {
                    expectObserveToNotReceiveOtherEvents.fulfill()
                }
            }, onSubscribe: {
                expectObserveToBegin.fulfill()
            }, onDispose: {
                expectObserveToNotDispose.fulfill()
            })
            .subscribe()

        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.failure(firstFetchFail))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_failUpdateExistingCache_continueToReceiveCacheUpdates() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        let fetchFail = Fail()

        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        let observeCacheData = ReplaySubject<String>.createUnbounded()
        observeCacheData.onNext(existingCache)

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheData.asObservable(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        /**
         We can't test exact cache states in the observer. That's because the repository's observing of a cache and fetching data are both async operations that jump between differnet threads. We mostly care that (1) we are observing caches and (2) a fetch failed and we are able to continue observing data after.

         Therefore, we pull apart the cache state with separate expectations to respect the async operations updating the cache state.
         */
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        expectToReceiveExistingCache.assertForOverFulfill = false

        let expectToReceiveFailedFetch = expectation(description: "Expect to receive failed fetching fresh cache")
        expectToReceiveFailedFetch.assertForOverFulfill = false

        let expectToNotDispose = expectation(description: "Expect to not dispose")
        expectToNotDispose.isInverted = true

        // This will prove that we can receive updates after the fetch failed.
        let expectToReceiveCacheUpdateAfterFailedFetch = expectation(description: "Expect to receive cache update after failed fetch")
        expectToReceiveCacheUpdateAfterFailedFetch.assertForOverFulfill = false

        let cacheAfterFetch = "cache after fetch"

        compositeDisposable += repository.observe()
            .do(onNext: { state in
                if state.cacheData == existingCache {
                    expectToReceiveExistingCache.fulfill()
                }

                if state.errorDuringFetch != nil {
                    expectToReceiveFailedFetch.fulfill()
                }

                if state.cacheData == cacheAfterFetch {
                    expectToReceiveCacheUpdateAfterFailedFetch.fulfill()
                }
            }, onDispose: {
                expectToNotDispose.fulfill()
            })
            .subscribe()

        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.failure(fetchFail))
        fetchFreshDataSubject.onCompleted()

        wait(for: [
            expectToReceiveExistingCache, expectToReceiveFailedFetch
        ], timeout: TestConstants.AWAIT_DURATION)

        observeCacheData.onNext(cacheAfterFetch)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_successfulFirstFetch_beginObservingCache() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        let firstFetchData = "new cache"
        let firstFetchTime = Date()
        let requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: firstFetchTime))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(firstFetchData), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        let expectToBeginObserving = expectation(description: "Expect to begin observing")
        let expectFirstFetchEvent = expectation(description: "Expect to receive first fetch happening event")
        let expectSuccessfulFirstFetchEvent = expectation(description: "Expect to receive successful first fetch event")
        let expectFirstCacheEvent = expectation(description: "Expect to receive first fetch event")
        let expectToNotDispose = expectation(description: "Expect to not dispose")
        expectToNotDispose.isInverted = true

        let firstFetchState = try! DataStateStateMachine<String>
            .noCacheExists(requirements: requirements).change()
            .firstFetch()

        func getFirstCacheEvent() -> DataState<String>? {
            guard let timeFetched = syncStateManager.updateAgeOfData_age else {
                return nil
            }
            return try! DataStateStateMachine
                .cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
                .cachedData(firstFetchData)
        }

        compositeDisposable += repository.observe()
            .do(onNext: { state in
                if state == firstFetchState {
                    expectFirstFetchEvent.fulfill()
                }
                if state.justCompletedSuccessfulFirstFetch {
                    expectSuccessfulFirstFetchEvent.fulfill()
                }
                if let firstCacheEvent = getFirstCacheEvent(), state == firstCacheEvent {
                    expectFirstCacheEvent.fulfill()
                }
            }, onSubscribe: {
                expectToBeginObserving.fulfill()
            }, onDispose: {
                expectToNotDispose.fulfill()
            })
            .subscribe()

        syncStateManager.updateAgeOfDataListener = {
            true
        }

        repository.requirements = requirements

        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.success(firstFetchData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    // https://github.com/levibostian/Teller-iOS/issues/32
    func test_multipleRepositoryInstances_firstFetch() {
        let firstFetchTime = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: firstFetchTime))
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        let firstDataSource = MockRepositoryDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(""), fetchFreshData: fetchFreshDataSubject.asSingle()), maxAgeOfCache: Period(unit: 1, component: Calendar.Component.second))
        let firstRefreshManager: RepositoryRefreshManager = AppRepositoryRefreshManager()

        let firstRepo: TellerRepository<MockRepositoryDataSource> = TellerRepository(dataSource: firstDataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: firstRefreshManager)

        let requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)
        firstRepo.requirements = requirements

        let firstFetchState = try! DataStateStateMachine<String>
            .noCacheExists(requirements: requirements).change()
            .firstFetch()

        let expectFirstRepoToBeginFirstFetch = expectation(description: "Expect first repo to begin first fetch of data.")
        let expectFirstRepoToSuccessfullyFinishFirstFetch = expectation(description: "Expect first repo to have a successful first fetch")

        compositeDisposable += firstRepo.observe()
            .debug("first", trimOutput: false)
            .do(onNext: { state in
                if state == firstFetchState {
                    expectFirstRepoToBeginFirstFetch.fulfill()
                }
                if state.justCompletedSuccessfulFirstFetch {
                    expectFirstRepoToSuccessfullyFinishFirstFetch.fulfill()
                }
            })
            .subscribe()

        wait(for: [expectFirstRepoToBeginFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        let secondFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        let secondDataSource = MockRepositoryDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(""), fetchFreshData: secondFreshDataSubject.asSingle()), maxAgeOfCache: Period(unit: 1, component: Calendar.Component.second))
        let secondRefreshManager: AppRepositoryRefreshManager = AppRepositoryRefreshManager()

        let secondRepo: TellerRepository<MockRepositoryDataSource> = TellerRepository(dataSource: secondDataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: secondRefreshManager)
        secondRepo.requirements = requirements

        let expectSecondRepoToBeginFirstFetch = expectation(description: "Expect second repo to begin first fetch of data.")
        let expectSecondRepoToSuccessfullyFinishFirstFetch = expectation(description: "Expect second repo to have a successful first fetch")

        compositeDisposable += secondRepo.observe()
            .debug("second", trimOutput: false)
            .do(onNext: { state in
                if state == firstFetchState {
                    expectSecondRepoToBeginFirstFetch.fulfill()
                }
                if state.justCompletedSuccessfulFirstFetch {
                    expectSecondRepoToSuccessfullyFinishFirstFetch.fulfill()
                }
            })
            .subscribe()

        wait(for: [expectSecondRepoToBeginFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            true
        }
        let firstFetchData = "first fetch"
        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.success(firstFetchData))
        fetchFreshDataSubject.onCompleted()

        wait(for: [expectFirstRepoToSuccessfullyFinishFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        let secondFetchData = "second fetch"
        secondFreshDataSubject.onNext(FetchResponse<String, Error>.success(secondFetchData))
        secondFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    /**
     `TellerRepository` has a shared instance of refresh manager. That means that refresh calls are shared between different repository instances. We expect each repository to recieve all of the same calls such as fetching status and delegate calls.
     */
    func test_multipleRepositoryInstances_refresh_givenFirstRepositoryStartsRefreshBeforeSecondRepoInit_expectBothRepositoriesGetSameBehaviors() {
        let firstFetchTime = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: firstFetchTime))
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(""), fetchFreshData: fetchFreshDataSubject.asSingle()))

        let firstRepo: TellerRepository<MockRepositoryDataSource> = TellerRepository(dataSource: dataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: refreshManager)

        let requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)
        firstRepo.requirements = requirements

        let expectFirstRepoRefreshSuccessful = expectation(description: "Expect first repo refresh success")

        compositeDisposable += try! firstRepo.refresh(force: true)
            .do(onSuccess: { refreshResult in
                switch refreshResult {
                case .successful: expectFirstRepoRefreshSuccessful.fulfill()
                case .failedError(error: _): XCTFail()
                case .skipped(reason: _): XCTFail()
                }
            })
            .subscribe()

        let secondRepo: TellerRepository<MockRepositoryDataSource> = TellerRepository(dataSource: dataSource, syncStateManager: syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: refreshManager)
        secondRepo.requirements = requirements

        let expectSecondRepoRefreshSuccessful = expectation(description: "Expect second repo refresh success")

        compositeDisposable += try! firstRepo.refresh(force: true)
            .do(onSuccess: { refreshResult in
                switch refreshResult {
                case .successful: expectSecondRepoRefreshSuccessful.fulfill()
                case .failedError(error: _): XCTFail()
                case .skipped(reason: _): XCTFail()
                }
            })
            .subscribe()

        let fetchData = "shared fetch complete"
        fetchFreshDataSubject.onNext(FetchResponse<String, Error>.success(fetchData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_firstFetch_failSavingNewCache_expectObserveError() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        let requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)
        repository.requirements = requirements

        let fetchedData = "new cache"

        enum FailSavingCache: Error {
            case cacheSaveFail
        }

        let saveCacheFail = FailSavingCache.cacheSaveFail
        let expectToSaveCache = expectation(description: "Expect to save cache")
        dataSource.saveDataThen = { newCache in
            expectToSaveCache.fulfill()
            throw saveCacheFail
        }

        let expectToNotUpdateAgeOfCache = expectation(description: "Expect to not update the age of data")
        expectToNotUpdateAgeOfCache.isInverted = true
        syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            expectToNotUpdateAgeOfCache.fulfill()
            return true
        }

        let expectToObserveSaveCacheError = expectation(description: "Expect to observe save cache error")
        compositeDisposable += repository.observe()
            .do(onNext: { state in
                let errorFirstFetchState = try! DataStateStateMachine<String>
                    .noCacheExists(requirements: requirements).change()
                    .firstFetch().change()
                    .errorFirstFetch(error: saveCacheFail)

                if state == errorFirstFetchState {
                    expectToObserveSaveCacheError.fulfill()
                }
            })
            .subscribe()

        fetchFreshDataSubject.onNext(FetchResponse.success(fetchedData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_observeCache_givenCache_castToOtherType_expectNewCache() {
        let lastFetched = Date()
        let existingCache = "1"
        let expectedNewCache: Double = Double(existingCache)!
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastFetched))
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache)))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let expectedCache = try! DataStateStateMachine<Double>.cacheExists(requirements: repository.requirements!, lastTimeFetched: lastFetched).change()
            .cachedData(expectedNewCache)

        let expectToObserveCache = expectation(description: "Expect to observe cache")
        compositeDisposable += repository.observe()
            .map { (cacheState) -> DataState<Double> in
                cacheState.convert { (existingCache) -> Double? in
                    expectedNewCache
                }
            }
            .subscribe(onNext: { state in
                if state == expectedCache {
                    expectToObserveCache.fulfill()
                }
            })

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_refreshIfNoCache_givenCacheDoesNotExist_expectRefresh() {
        let givenFailure = Fail()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse<String, Error>.failure(givenFailure))))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            true
        }

        let actual = try! repository.refreshIfNoCache()
            .toBlocking()
            .first()!

        XCTAssertEqual(dataSource.fetchFreshDataCount, 2) // 2 refresh calls. One when set requirements, second when call `refreshIfNoCache()`
        XCTAssertEqual(actual, RefreshResult.failedError(error: givenFailure))
    }

    func test_refreshIfNoCache_givenCacheDoesExist_expectNoRefresh() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse<String, Error>.success(""))))
        initRepository()
        repository.requirements = MockRepositoryDataSource.MockRequirements(randomString: nil)

        let actual = try! repository.refreshIfNoCache()
            .toBlocking()
            .first()!

        XCTAssertEqual(dataSource.fetchFreshDataCount, 0)
        XCTAssertEqual(actual, .successful)
    }

    private class Fail: Error {}
}
