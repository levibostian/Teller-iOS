//
//  OnlineRepositoryTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Teller

/**
 You will notice a lot of expectation statements here. That is because the OnlineRepository and OnlineRepositoryRefreshManager use different threads for some processes. This makes this code run async and we need to use expectations to wait for some threads to be done and come back for results.
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
class OnlineRepositoryTest: XCTestCase {
    
    private var repository: OnlineRepository<MockOnlineRepositoryDataSource>!
    private var dataSource: MockOnlineRepositoryDataSource!
    private var syncStateManager: MockRepositorySyncStateManager!
    private var refreshManager: AnyOnlineRepositoryRefreshManager<String> = AnyOnlineRepositoryRefreshManager(AppOnlineRepositoryRefreshManager())
    
    private var compositeDisposable: CompositeDisposable!
    
    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        
        TellerUserDefaultsUtil.shared.clear()
        initDataSource(fakeData: self.getDataSourceFakeData())
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData())
        initRepository()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        compositeDisposable.dispose()
        compositeDisposable = nil
    }

    private func getFirstFetchEvent() -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine
            .noCacheExists(requirements: self.repository.requirements!).change()
            .firstFetch()
    }

    private func getCacheEmptyEvent(lastTimeFetched: Date) -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine
            .cacheExists(requirements: self.repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .cacheIsEmpty()
    }

    private func getErrorFirstFetchEvent(_ error: Error) -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine
            .noCacheExists(requirements: self.repository.requirements!).change()
            .firstFetch().change()
            .errorFirstFetch(error: error)
    }

    private func getCacheDataEvent(lastTimeFetched: Date, cachedData: String) -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine
            .cacheExists(requirements: self.repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .cachedData(cachedData)
    }

    private func getCacheExistsNotRefreshingEvent(lastTimeFetched: Date) -> OnlineDataState<String> {
        return OnlineDataStateStateMachine<String>
            .cacheExists(requirements: self.repository.requirements!, lastTimeFetched: lastTimeFetched)
    }

    private func getCacheDoesNotExistNotFetchingEvent() -> OnlineDataState<String> {
        return OnlineDataStateStateMachine<String>
            .noCacheExists(requirements: self.repository.requirements!)
    }

    private func getCacheExistsRefreshingEvent(lastTimeFetched: Date) -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine<String>
            .cacheExists(requirements: self.repository.requirements!, lastTimeFetched: lastTimeFetched).change()
            .fetchingFreshCache()
    }
    
    private func getDataSourceFakeData(isDataEmpty: Bool = false, observeCachedData: Observable<String> = Observable.empty(), fetchFreshData: Single<FetchResponse<String>> = Single.never()) -> MockOnlineRepositoryDataSource.FakeData {
        return MockOnlineRepositoryDataSource.FakeData(isDataEmpty: isDataEmpty, observeCachedData: observeCachedData, fetchFreshData: fetchFreshData)
    }
    
    private func getSyncStateManagerFakeData(isDataTooOld: Bool = false, hasEverFetchedData: Bool = false, lastTimeFetchedData: Date? = nil) -> MockRepositorySyncStateManager.FakeData {
        return MockRepositorySyncStateManager.FakeData(isDataTooOld: isDataTooOld, hasEverFetchedData: hasEverFetchedData, lastTimeFetchedData: lastTimeFetchedData)
    }
    
    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initDataSource(fakeData: MockOnlineRepositoryDataSource.FakeData, maxAgeOfData: Period = Period(unit: 1, component: Calendar.Component.second)) {
        self.dataSource = MockOnlineRepositoryDataSource(fakeData: fakeData, maxAgeOfData: maxAgeOfData)
    }
    
    // When test function runs, the `RepositorySyncStateManager` will already be initialized, but you can override it by calling this function again to inject it into the repository.
    private func initSyncStateManager(syncStateManagerFakeData: MockRepositorySyncStateManager.FakeData) {
        self.syncStateManager = MockRepositorySyncStateManager(fakeData: syncStateManagerFakeData)
    }
    
    private func initRepository() {
        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: self.refreshManager) // Use AppSchedulersProvider to test on read multi-threading. Bugs in Teller have been missed from using a single threaded environment.
    }
    
    func test_refresh_requirementsNotSet_throwError() {
        initRepository()
        self.repository.requirements = nil
        
        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        XCTAssertThrowsError(try self.repository.refresh(force: true).asObservable().subscribe(observer).dispose())
    }

    func test_init() {
        initDataSource(fakeData: getDataSourceFakeData())
        self.repository = OnlineRepository(dataSource: self.dataSource)

        XCTAssertNotNil(self.repository.refreshManager.delegate)
    }

    func test_dataSourceGetObservableCacheData_calledOnMainThread() {
        let expectToGetObservable = expectation(description: "Expect to get observable to observe cached data")
        expectToGetObservable.expectedFulfillmentCount = 1 // 1. When setting requirements, OnlineRepository begins observing cache. 2. Refresh call when observing cache in OnlineRepository. 3. Refresh call when setting requirements.
        expectToGetObservable.assertForOverFulfill = false // It might be fullfilled 3 times, or 2 times. This is hard to fix at this time until the test API for mocking it improved.

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false))

        DispatchQueue.global(qos: .background).async {
            XCTAssertFalse(Thread.isMainThread)

            self.dataSource.observeCacheDataThenAnswer = { requirements in
                XCTAssertTrue(Thread.isMainThread)
                expectToGetObservable.fulfill()

                return Observable.just("")
            }

            // Test when begin to observe cache on background thread
            self.initRepository()
            self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        }

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_deinit_cancelExistingRefreshStopObserving() {
        let existingCache = "existing cache"
        let existingCacheFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: existingCacheFetched))
        let observeCache: Observable<String> = Observable.create({ $0.onNext(existingCache); return Disposables.create() }) // Make an Observable that does not complete on it's own like: Observable.just() to test that `deinit` completes for us.
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCache, fetchFreshData: Single.never()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectToBeginObserving = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToComplete = expectation(description: "Expect to complete observing of cache")
        let expectToDisposeObservingCache = expectation(description: "Expect to dispose observing of cache")

        let existingCacheEvent = self.getCacheDataEvent(lastTimeFetched: existingCacheFetched, cachedData: existingCache)

        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
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
        compositeDisposable += try! self.repository.refresh(force: true)
            .do(onSuccess: { (refreshResult) in
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

        self.repository = nil

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_setNewRequirements_refreshGetsCancelled() {
        let mockRefreshManager = MockOnlineRepositoryRefreshManager<String>()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        self.refreshManager = AnyOnlineRepositoryRefreshManager(mockRefreshManager)

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        // Set requirements for first time starts the first refresh
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        XCTAssertEqual(mockRefreshManager.invokedCancelRefreshCount, 1)

        wait(for: [expectRefreshToBegin], timeout: TestConstants.AWAIT_DURATION)

        // Set requirements for second time will cancel the previous refresh call
        self.repository.requirements = nil

        XCTAssertEqual(mockRefreshManager.invokedCancelRefreshCount, 2)
    }

    func test_setRequirementsNil_observeNoneStateOfData() {
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let existingCache = "existing cache"
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache), fetchFreshData: Single.never()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectToBeginObservingCache = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToReceiveNoneDataState = expectation(description: "Expect to receive none data state")
        let expectToNotDispose = expectation(description: "Expect to not stop observing")
        expectToNotDispose.isInverted = true
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state.cacheData == existingCache {
                    expectToReceiveExistingCache.fulfill()
                }
                if state == OnlineDataState.none() {
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
        self.repository.requirements = nil

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_setRequirementsNilThenNotNil_continueToObserveSequence() {
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let existingCache = "existing cache"
        let newCache = "new cache"
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.create({ $0.onNext(existingCache); return Disposables.create() }), fetchFreshData: Single.never()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectToBeginObservingCache = expectation(description: "Expect to begin observing cache")
        let expectToReceiveExistingCache = expectation(description: "Expect to receive existing cache")
        let expectToReceiveNewCache = expectation(description: "Expect to receive new cache")
        let expectToReceiveNoneDataState = expectation(description: "Expect to receive none data state")
        let expectToNotDispose = expectation(description: "Expect to not stop observing")
        expectToNotDispose.isInverted = true
        compositeDisposable += self.repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (state) in
                if state.cacheData == existingCache {
                    expectToReceiveExistingCache.fulfill()
                }
                if state.cacheData == newCache {
                    expectToReceiveNewCache.fulfill()
                }
                if state == OnlineDataState.none() {
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
        self.repository.requirements = nil

        wait(for: [expectToReceiveNoneDataState], timeout: TestConstants.AWAIT_DURATION)

        self.dataSource.fakeData.observeCachedData = Observable.create({ $0.onNext(newCache); return Disposables.create() })
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_saveCacheDataIsCalledOnBackgroundThread() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let fetchedData = "new cache"

        let expectDataSourceToSaveFetchedResponse = expectation(description: "Wait for data source saveData to be called.")

        self.dataSource.saveDataThen = { newCache in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(newCache, fetchedData)

            expectDataSourceToSaveFetchedResponse.fulfill()
        }

        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        fetchFreshDataSubject.onNext(FetchResponse.success(fetchedData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_neverFetchedData_setRequirements_refreshGetsTriggered() {
        let mockRefreshManager = MockOnlineRepositoryRefreshManager<String>()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        self.refreshManager = AnyOnlineRepositoryRefreshManager(mockRefreshManager)

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        // Set requirements for first time starts the first refresh
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        wait(for: [expectRefreshToBegin], timeout: TestConstants.AWAIT_DURATION)
    }

    func test_cacheExistsButIsTooOld_setRequirementsBeginsFetch() {
        let mockRefreshManager = MockOnlineRepositoryRefreshManager<String>()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        self.refreshManager = AnyOnlineRepositoryRefreshManager(mockRefreshManager)

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()

        // Set requirements for first time starts the first refresh
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cacheExistsButIsTooOld_observeNewCacheAfterSuccessfulFetch() {
        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date.init(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        let newlyFetchedCache = "new cache"

        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        let observeCacheDataObservable = BehaviorSubject<String>.init(value: existingCache)
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheDataObservable, fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        let expectStartObserving = expectation(description: "Expect observe to start observing cache")
        let expectToReceiveOldCache = expectation(description: "Expect to observe old cache data")
        expectToReceiveOldCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectToReceiveNewCache = expectation(description: "Expect to observe new cache data")
        expectToReceiveNewCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose and continue observing")
        expectObserveToNotDispose.isInverted = true
        
        compositeDisposable += self.repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (state) in
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
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        wait(for: [expectStartObserving, expectToReceiveOldCache], timeout: TestConstants.AWAIT_DURATION)

        self.dataSource.saveDataThen = { newCache in
            observeCacheDataObservable.on(.next(newCache))
        }
        fetchFreshDataSubject.onNext(FetchResponse<String>.success(newlyFetchedCache))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_canObserveWithoutSettingRequirements() {
        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date.init(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(existingCache), fetchFreshData: Single.never()))
        initRepository()
        // do not set requirements on the repository, yet.

        let expectStartObserving = expectation(description: "Expect observe to start observing cache")
        let expectToReceiveANoneStateFirst = expectation(description: "Expect to receive a none state first")
        let expectToReceiveOldCache = expectation(description: "Expect to observe old cache data")
        expectToReceiveOldCache.assertForOverFulfill = false // I need to assert it runs at least once.
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose and continue observing")
        expectObserveToNotDispose.isInverted = true

        compositeDisposable += self.repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (state) in
                if state == OnlineDataState.none() {
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

        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cacheExistsNotTooOld_skipRefresh() {
        let mockRefreshManager = MockOnlineRepositoryRefreshManager<String>()
        let stubbedRefreshResultSubject = ReplaySubject<RefreshResult>.createUnbounded()

        let expectRefreshToNotBegin = expectation(description: "Expect refresh to not begin.")
        expectRefreshToNotBegin.isInverted = true

        let stubbedRefreshResultObservable = stubbedRefreshResultSubject
            .asSingle()
            .do(onSubscribe: {
                expectRefreshToNotBegin.fulfill()
            })

        mockRefreshManager.stubbedRefreshResult = stubbedRefreshResultObservable
        self.refreshManager = AnyOnlineRepositoryRefreshManager(mockRefreshManager)

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        // Trigger observe to test fetch does not happen here as well.
        compositeDisposable += self.repository.observe().subscribe()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_forceRefreshStartsRefreshEvenIfDataNotTooOld() {
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let fetchFreshData = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: fetchFreshData.asSingle()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")
        let expectRefreshToBeSuccessful = expectation(description: "Expect refresh to be successful")
        compositeDisposable += try! self.repository.refresh(force: true)
            .do(onSuccess: { (refreshResult) in
                if refreshResult == .successful {
                    expectRefreshToBeSuccessful.fulfill()
                }
            }, onSubscribe: {
                expectRefreshToBegin.fulfill()
            })
            .subscribe()

        fetchFreshData.onNext(FetchResponse<String>.success("new data"))
        fetchFreshData.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_refresh_dataNotTooOld_skipsRefresh() {
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: Single.never()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectRefreshToBegin = expectation(description: "Expect refresh to begin.")
        let expectRefreshToBeSkipped = expectation(description: "Expect refresh to be skipped")
        compositeDisposable += try! self.repository.refresh(force: false)
            .do(onSuccess: { (refreshResult) in
                if refreshResult == .skipped(reason: .dataNotTooOld) {
                    expectRefreshToBeSkipped.fulfill()
                }
            }, onSubscribe: {
                expectRefreshToBegin.fulfill()
            })
            .subscribe()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_failedFirstFetchDoesNotBeginObservingCache() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        let firstFetchFail = Fail()

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("cache"), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectObserveToBegin = expectation(description: "Expect observe() to begin observing")
        let expectObserveToNotDispose = expectation(description: "Expect observe to not dispose")
        expectObserveToNotDispose.isInverted = true
        let expectObserveToReceiveNoneStateOrFirstFetch = expectation(description: "Expect observe to receive none state and first fetch")
        expectObserveToReceiveNoneStateOrFirstFetch.assertForOverFulfill = false
        let expectObserveToNotReceiveOtherEvents = expectation(description: "Expect observe to not receive any other events")
        expectObserveToNotReceiveOtherEvents.isInverted = true
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == self.getFirstFetchEvent() ||
                    state == OnlineDataState.none() ||
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

        fetchFreshDataSubject.onNext(FetchResponse<String>.failure(firstFetchFail))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_failUpdateExistingCache_continueToReceiveCacheUpdates() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        let fetchFail = Fail()

        let existingCache = "old cache"
        let existingCacheLastTimeFethed = Date.init(timeIntervalSince1970: Date().timeIntervalSince1970 - 5)

        let observeCacheData = ReplaySubject<String>.createUnbounded()
        observeCacheData.onNext(existingCache)

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: existingCacheLastTimeFethed))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheData.asObservable(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        let expectToBeginObserving = expectation(description: "Expect to begin observing")
        let expectToReceiveExistingCacheAndFetchingFresh = expectation(description: "Expect to receive existing cache and fetching fresh cache")
        let expectToReceiveExistingCacheAndFailedFetch = expectation(description: "Expect to receive existing cache and failed fetching fresh cache")
        let expectToNotDispose = expectation(description: "Expect to not dispose")
        expectToNotDispose.isInverted = true

        let existingCacheAndFetchingFreshCacheState = try! self.getCacheExistsRefreshingEvent(lastTimeFetched: existingCacheLastTimeFethed).change()
            .cachedData(existingCache)
        let existingCacheAndFailedFetch = try! self.getCacheExistsRefreshingEvent(lastTimeFetched: existingCacheLastTimeFethed).change()
            .cachedData(existingCache).change()
            .failFetchingFreshCache(fetchFail)

        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == existingCacheAndFetchingFreshCacheState {
                    expectToReceiveExistingCacheAndFetchingFresh.fulfill()
                }
                if state == existingCacheAndFailedFetch {
                    expectToReceiveExistingCacheAndFailedFetch.fulfill()
                }
            }, onSubscribe: {
                expectToBeginObserving.fulfill()
            }, onDispose: {
                expectToNotDispose.fulfill()
            })
            .subscribe()

        fetchFreshDataSubject.onNext(FetchResponse<String>.failure(fetchFail))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_successfulFirstFetch_beginObservingCache() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        let firstFetchData = "new cache"
        let firstFetchTime = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)

        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: firstFetchTime))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(firstFetchData), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()

        let expectToBeginObserving = expectation(description: "Expect to begin observing")
        let expectFirstFetchEvent = expectation(description: "Expect to receive first fetch happening event")
        let expectSuccessfulFirstFetchEvent = expectation(description: "Expect to receive successful first fetch event")
        let expectFirstCacheEvent = expectation(description: "Expect to receive first fetch event")
        let expectToNotDispose = expectation(description: "Expect to not dispose")
        expectToNotDispose.isInverted = true

        let firstFetchState = try! OnlineDataStateStateMachine<String>
            .noCacheExists(requirements: requirements).change()
            .firstFetch()

        func getFirstCacheEvent() -> OnlineDataState<String>? {
            guard let timeFetched = self.syncStateManager.updateAgeOfData_age else {
                return nil
            }
            return try! OnlineDataStateStateMachine
                .cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
                .cachedData(firstFetchData)
        }

        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
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

        self.syncStateManager.updateAgeOfDataListener = {
            return true
        }

        self.repository.requirements = requirements

        fetchFreshDataSubject.onNext(FetchResponse<String>.success(firstFetchData))
        fetchFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    // https://github.com/levibostian/Teller-iOS/issues/32
    func test_multipleRepositoryInstances_firstFetch() {
        let firstFetchTime = Date()
        initSyncStateManager(syncStateManagerFakeData: self.getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: firstFetchTime))
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        let firstDataSource = MockOnlineRepositoryDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(""), fetchFreshData: fetchFreshDataSubject.asSingle()), maxAgeOfData: Period(unit: 1, component: Calendar.Component.second))
        let firstRefreshManager: AnyOnlineRepositoryRefreshManager<String> = AnyOnlineRepositoryRefreshManager(AppOnlineRepositoryRefreshManager())

        let firstRepo: OnlineRepository<MockOnlineRepositoryDataSource> = OnlineRepository(dataSource: firstDataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: firstRefreshManager)

        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        firstRepo.requirements = requirements

        let firstFetchState = try! OnlineDataStateStateMachine<String>
            .noCacheExists(requirements: requirements).change()
            .firstFetch()

        let expectFirstRepoToBeginFirstFetch = expectation(description: "Expect first repo to begin first fetch of data.")
        let expectFirstRepoToSuccessfullyFinishFirstFetch = expectation(description: "Expect first repo to have a successful first fetch")

        compositeDisposable += firstRepo.observe()
            .debug("first", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchState {
                    expectFirstRepoToBeginFirstFetch.fulfill()
                }
                if state.justCompletedSuccessfulFirstFetch {
                    expectFirstRepoToSuccessfullyFinishFirstFetch.fulfill()
                }
            })
            .subscribe()

        wait(for: [expectFirstRepoToBeginFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        let secondFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        let secondDataSource = MockOnlineRepositoryDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(""), fetchFreshData: secondFreshDataSubject.asSingle()), maxAgeOfData: Period(unit: 1, component: Calendar.Component.second))
        let secondRefreshManager: AnyOnlineRepositoryRefreshManager<String> = AnyOnlineRepositoryRefreshManager(AppOnlineRepositoryRefreshManager())

        let secondRepo: OnlineRepository<MockOnlineRepositoryDataSource> = OnlineRepository(dataSource: secondDataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider(), refreshManager: secondRefreshManager)
        secondRepo.requirements = requirements

        let expectSecondRepoToBeginFirstFetch = expectation(description: "Expect second repo to begin first fetch of data.")
        let expectSecondRepoToSuccessfullyFinishFirstFetch = expectation(description: "Expect second repo to have a successful first fetch")

        compositeDisposable += secondRepo.observe()
            .debug("second", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchState {
                    expectSecondRepoToBeginFirstFetch.fulfill()
                }
                if state.justCompletedSuccessfulFirstFetch {
                    expectSecondRepoToSuccessfullyFinishFirstFetch.fulfill()
                }
            })
            .subscribe()

        wait(for: [expectSecondRepoToBeginFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        let firstFetchData = "first fetch"
        fetchFreshDataSubject.onNext(FetchResponse<String>.success(firstFetchData))
        fetchFreshDataSubject.onCompleted()

        wait(for: [expectFirstRepoToSuccessfullyFinishFirstFetch], timeout: TestConstants.AWAIT_DURATION)

        let secondFetchData = "second fetch"
        secondFreshDataSubject.onNext(FetchResponse<String>.success(secondFetchData))
        secondFreshDataSubject.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_firstFetch_failSavingNewCache_expectObserveError() {
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.never(), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.repository.requirements = requirements

        let fetchedData = "new cache"

        enum FailSavingCache: Error {
            case cacheSaveFail
        }

        let saveCacheFail = FailSavingCache.cacheSaveFail
        let expectToSaveCache = expectation(description: "Expect to save cache")
        self.dataSource.saveDataThen = { newCache in
            expectToSaveCache.fulfill()
            throw saveCacheFail
        }

        let expectToNotUpdateAgeOfCache = expectation(description: "Expect to not update the age of data")
        expectToNotUpdateAgeOfCache.isInverted = true
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            expectToNotUpdateAgeOfCache.fulfill()
            return true
        }

        let expectToObserveSaveCacheError = expectation(description: "Expect to observe save cache error")
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                let errorFirstFetchState = try! OnlineDataStateStateMachine<String>
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

    private class Fail: Error {
    }
    
}
