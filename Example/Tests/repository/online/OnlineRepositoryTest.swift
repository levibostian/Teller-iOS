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
 Some tests are run sync because I mock the threads to using the current one. However, testing using real threads is good for these tests as bugs happen when it runs in an async way. It's good to assert async code is working.

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
    
    private var compositeDisposable: CompositeDisposable!
    
    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        
        TellerUserDefaultsUtil.shared.clear()
        initDataSource(fakeData: self.getDataSourceFakeData())
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData())
        initRepository(requirements: nil)
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

    private func getSuccessfulFirstFetchEvent(timeFetched: Date) -> OnlineDataState<String> {
        return try! OnlineDataStateStateMachine
            .noCacheExists(requirements: self.repository.requirements!).change()
            .firstFetch().change()
            .successfulFirstFetch(timeFetched: timeFetched)
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
    
    private func initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements?) {
        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: TestsSchedulersProvider())
        self.repository.requirements = requirements
    }
    
    func test_refresh_requirementsNotSet_throwError() {
        initRepository(requirements: nil)
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        XCTAssertThrowsError(try self.repository.refresh(force: true).asObservable().subscribe(observer).dispose())
    }
    
    func test_observe_requirementsNotSet_willReceiveEventsOnceRequirementsSet() {
        initRepository(requirements: nil)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
        
        let lastFetched = Date()
        self.syncStateManager.fakeData = getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastFetched)
        self.dataSource.fakeData = getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just(""))
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.none(),
            OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastFetched),
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastFetched)
                .change()
                .cacheIsEmpty()])
    }
    
    func test_refresh_force_successfullyRefresh() {
        let force = true
        let data = "foo"
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data), fetchFreshData: Single.just(FetchResponse.success(data: data))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let refreshExpectSuccessfulSync = expectation(description: "Expect refresh to succeed")
        let refreshExpectComplete = expectation(description: "Expect refresh to complete")

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: force)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    refreshExpectSuccessfulSync.fulfill()
                }
            }, onDispose: {
                refreshExpectComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        wait(for: [refreshExpectSuccessfulSync, refreshExpectComplete], timeout: 2.0)
        
        XCTAssertEqual(self.dataSource.fetchFreshDataCount, 1)
        XCTAssertEqual(self.dataSource.fetchFreshDataRequirements, repository.requirements)
        XCTAssertEqual(self.dataSource.saveDataCount, 1)
        XCTAssertEqual(self.dataSource.saveDataFetchedData, data)
        XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 1)
    }
    
    func test_refresh_failed() {
        let errorMessage = "failed message"
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(message: errorMessage)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let refreshExpectToComplete = expectation(description: "Expect to complete")
        let refreshExpectToFail = expectation(description: "Expect to fail fetch")
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.fail(FetchResponse<String>.fail(message: errorMessage).failure!) {
                    refreshExpectToFail.fulfill()
                }
            }, onDispose: {
                refreshExpectToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        wait(for: [refreshExpectToComplete, refreshExpectToFail], timeout: 1.0)

        XCTAssertEqual(self.dataSource.saveDataCount, 0)
        XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 0)
    }
    
    func test_refresh_skipped() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let refreshExpectToBeSkipped = expectation(description: "Expect refresh to skip")
        let refreshExpectToComplete = expectation(description: "Expect to complete task")
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld) {
                    refreshExpectToBeSkipped.fulfill()
                }
            }, onDispose: {
                refreshExpectToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        wait(for: [refreshExpectToBeSkipped, refreshExpectToComplete], timeout: 1.0)
    }

    func test_refresh_multipleObserversGetSameEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        let data = "data"
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.success(data: data))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observerRefreshExpectToSucceed = expectation(description: "Expect refresh to succeed")
        let observerRefreshExpectToComplete = expectation(description: "Expect refresh to complete")

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    observerRefreshExpectToSucceed.fulfill()
                }
            }, onDispose: {
                observerRefreshExpectToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        let observer2RefreshExpectToSucceed = expectation(description: "Expect refresh to succeed")
        let observer2RefreshExpectToComplete = expectation(description: "Expect refresh to complete")

        let observer2 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    observer2RefreshExpectToSucceed.fulfill()
                }
            }, onDispose: {
                observer2RefreshExpectToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer2)

        wait(for: [observerRefreshExpectToSucceed, observerRefreshExpectToComplete,
                   observer2RefreshExpectToSucceed, observer2RefreshExpectToComplete], timeout: 1.0)
    }

    func test_refresh_observerGetsCancelledAfterSettingRequirements() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single<FetchResponse<String>>.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let refreshGetsCancelled = expectation(description: "Expect refresh to get cancelled")
        let refreshGetsDisposed = expectation(description: "Expect refresh to get disposed")

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.skipped(SyncResult.SkippedReason.cancelled) {
                    refreshGetsCancelled.fulfill()
                }
            }, onDispose: {
                refreshGetsDisposed.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "new requirements")

        wait(for: [refreshGetsCancelled, refreshGetsDisposed], timeout: 1.0)
    }
    
    func test_observe_firstFetch_refreshes() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: Single.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let firstFetchEvent = getFirstFetchEvent()

        let observeExpectFirstFetch = expectation(description: "Expect first fetch to trigger after observe")
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observeExpectFirstFetch.fulfill()
                }
            })
            .subscribe(observer)

        wait(for: [observeExpectFirstFetch], timeout: 1.0)
    }

    // Test: https://github.com/levibostian/Teller-iOS/issues/24
    func test_observeAfterSetRequirements_callsRefreshTwice() {
        let fail = Fail()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse<String>.fail(error: fail))))

        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider())
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.repository.requirements = requirements

        // Test is flaky when trying to test for more then this event. This event needs to run, but because of threading, it's difficult to predict what else will run. Expect this 1 event at a minimum.
        let expectRefreshToFail = expectation(description: "Expect to fail first refresh")

        let errorFetchEvent = getErrorFirstFetchEvent(fail)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { (state) in
                if state == errorFetchEvent {
                    expectRefreshToFail.fulfill()
                }
            })
            .subscribe(observer)

        wait(for: [expectRefreshToFail], timeout: 1.0)
    }

    func test_multipleRefreshAtSameTime_sameEventsNoErrors() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))

        let refreshFetchTask = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: refreshFetchTask.asSingle()))

        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider())
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.repository.requirements = requirements

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .debug("ref-observe", trimOutput: false)
            .subscribe(observer)

        let refresh1ExpectOnNext = expectation(description: "Receive success call.")
        let refresh1ExpectComplete = expectation(description: "Expect to complete.")

        let refresh1 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository
            .refresh(force: true)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onSuccess: { (result) in
                if result == SyncResult.success() {
                    refresh1ExpectOnNext.fulfill()
                }
            }, onDispose: {
                refresh1ExpectComplete.fulfill()
            })
            .asObservable()
            .debug("ref-1", trimOutput: false)
            .subscribe(refresh1)

        let refresh2ExpectOnNext = expectation(description: "Receive success call.")
        let refresh2ExpectComplete = expectation(description: "Expect to complete.")

        let refresh2 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository
            .refresh(force: true)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onSuccess: { (result) in
                if result == SyncResult.success() {
                    refresh2ExpectOnNext.fulfill()
                }
            }, onDispose: {
                refresh2ExpectComplete.fulfill()
            })
            .asObservable()
            .debug("ref-2", trimOutput: false).subscribe(refresh2)

        refreshFetchTask.onNext(FetchResponse.success(data: "cache"))
        refreshFetchTask.onCompleted()

        wait(for: [refresh1ExpectOnNext, refresh1ExpectComplete,
                   refresh2ExpectOnNext, refresh2ExpectComplete], timeout: 1.0)
    }
    
    func test_observe_firstFetchFailed_butStillObserving() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let fetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let fetchedData = "data"
        let dataLastFetched = Date()

        let expectFirstFetchCalls = expectation(description: "Expect first fetch to be called.")
        expectFirstFetchCalls.expectedFulfillmentCount = 2
        let expectFirstFetchToFail = expectation(description: "Expect first fetch call to fail")
        let expectFirstFetchToSucceed = expectation(description: "Expect first fetch call to succeed")
        let expectCache = expectation(description: "Expect cache to not be empty")

        let firstFetchEvent = getFirstFetchEvent()
        let errorFetchEvent = getErrorFirstFetchEvent(fetchFail)
        let successfulFirstFetchEvent = getSuccessfulFirstFetchEvent(timeFetched: dataLastFetched)
        let cacheDataEvent = getCacheDataEvent(lastTimeFetched: dataLastFetched, cachedData: fetchedData)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    expectFirstFetchCalls.fulfill()
                }
                if state == errorFetchEvent {
                    expectFirstFetchToFail.fulfill()
                }
                if state == successfulFirstFetchEvent {
                    expectFirstFetchToSucceed.fulfill()
                }
                if state == cacheDataEvent {
                    expectCache.fulfill()
                }
            })
            .subscribe(observer)

        fetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        fetchFreshDataSubject.onCompleted()

        let secondFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = secondFetchFreshDataSubject.asSingle()
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        self.dataSource.fakeData.observeCachedData = Observable.just(fetchedData)
        self.dataSource.fakeData.isDataEmpty = false
        self.syncStateManager.fakeData.lastTimeFetchedData = dataLastFetched
        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver)

        secondFetchFreshDataSubject.onNext(FetchResponse.success(data: fetchedData))
        secondFetchFreshDataSubject.onCompleted()

        wait(for: [expectFirstFetchCalls,
                   expectFirstFetchToFail,
                   expectFirstFetchToSucceed,
                   expectCache], timeout: 1.0)
    }
    
    func test_observe_firstFetchFail_callingObserveAgainTriggersRefresh() { // After a first fetch failing, you can call refresh or observe in order to trigger an update.
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))

        let fetchFail = Fail()
        let fetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observeExpectFirstFetchCalls = expectation(description: "observer: Expect first fetch calls.")
        observeExpectFirstFetchCalls.expectedFulfillmentCount = 2
        let observeExpectFirstFetchCallsToError = expectation(description: "observer: Expect first fetch calls to fail.")
        observeExpectFirstFetchCallsToError.expectedFulfillmentCount = 2

        let firstFetchEvent = getFirstFetchEvent()
        let errorFetchEvent = getErrorFirstFetchEvent(fetchFail)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .debug("obs--1", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observeExpectFirstFetchCalls.fulfill()
                }
                if state == errorFetchEvent {
                    observeExpectFirstFetchCallsToError.fulfill()
                }
            })
            .subscribe(observer)

        fetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        fetchFreshDataSubject.onCompleted()

        let secondObserveExpectFirstFetch = expectation(description: "observer2: Expect first fetch to trigger when start another observer")
        let secondObserveExpectFirstFetchFail = expectation(description: "observer2: Expect first fetch to fail on second observer")

        // You need to set a new Single instance after the first fetch is done as the old instance completed and disposed.
        let secondFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = secondFetchFreshDataSubject.asSingle()
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .debug("obs--2", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    secondObserveExpectFirstFetch.fulfill()
                }
                if state == errorFetchEvent {
                    secondObserveExpectFirstFetchFail.fulfill()
                }
            })
            .subscribe(observer2)

        secondFetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        secondFetchFreshDataSubject.onCompleted()

        wait(for: [observeExpectFirstFetchCalls, observeExpectFirstFetchCallsToError,
                   secondObserveExpectFirstFetch, secondObserveExpectFirstFetchFail], timeout: 1.0)
    }
    
    func test_multipleObserversOfRepository_getSameEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let fetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let firstFetchEvent = getFirstFetchEvent()
        let errorFetchEvent = getErrorFirstFetchEvent(fetchFail)

        let observerExpectFirstFetch = expectation(description: "observer: Expect first fetch calls")
        observerExpectFirstFetch.expectedFulfillmentCount = 2
        let observerExpectFirstFetchErrors = expectation(description: "observer: Expect first fetch calls to error.")
        observerExpectFirstFetchErrors.expectedFulfillmentCount = 2
        let observerDisposed = expectation(description: "Expect to have observer get disposed")
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let observerDisposable = self.repository.observe()
            .debug("ob1", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observerExpectFirstFetch.fulfill()
                }
                if state == errorFetchEvent {
                    observerExpectFirstFetchErrors.fulfill()
                }
            }, onDispose: {
                observerDisposed.fulfill()
            })
            .subscribe(observer)

        fetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        fetchFreshDataSubject.onCompleted()

        let observer2ExpectFirstFetch = expectation(description: "observer2: Expect first fetch calls")
        observer2ExpectFirstFetch.expectedFulfillmentCount = 2
        let observer2ExpectFirstFetchErrors = expectation(description: "observer2: Expect first fetch calls to error.")
        observer2ExpectFirstFetchErrors.expectedFulfillmentCount = 2

        let secondFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = secondFetchFreshDataSubject.asSingle()

        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .debug("ob2", trimOutput: false)
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observer2ExpectFirstFetch.fulfill()
                }
                if state == errorFetchEvent {
                    observer2ExpectFirstFetchErrors.fulfill()
                }
            })
            .subscribe(observer2)

        secondFetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        secondFetchFreshDataSubject.onCompleted()
        
        // Test that if 1 observer disposes, we can continue to observe changes as disposing of an observable will not dispose of the observable in the repository.
        observerDisposable.dispose()

        wait(for: [observerExpectFirstFetch, observerExpectFirstFetchErrors, observerDisposed], timeout: 1.0)

        let refreshExpectation = expectation(description: "Wait until fail comes in")

        let thirdFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = thirdFetchFreshDataSubject.asSingle()

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true).asObservable()
            .do(onNext: { (result) in
                if result.didFail() {
                    refreshExpectation.fulfill()
                }
            })
            .subscribe(refreshObserver)

        thirdFetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        thirdFetchFreshDataSubject.onCompleted()

        wait(for: [observer2ExpectFirstFetch, observer2ExpectFirstFetchErrors,
                   refreshExpectation], timeout: 2.0)
    }
    
    func test_multipleObserversOfRepository_changeRequirements_continueToGetNewEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let fetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: fetchFreshDataSubject.asSingle())
        initDataSource(fakeData: dataSourceFakeData)
        let firstRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "first")
        initRepository(requirements: firstRequirements)

        let firstFetchEvent = getFirstFetchEvent()
        let errorFetchEvent = getErrorFirstFetchEvent(fetchFail)
        let secondRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "second")

        let observerExpectFirstFetchCalls = expectation(description: "observer: Expect first fetch to call multiple times.")
        observerExpectFirstFetchCalls.expectedFulfillmentCount = 3
        let observerExpectFirstFetchErrors = expectation(description: "observer: Expect first fetch to error for multiple calls.")
        observerExpectFirstFetchErrors.expectedFulfillmentCount = 3

        var observerNumberTimesFirstFetching = 0
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observerExpectFirstFetchCalls.fulfill()
                }
                if state == errorFetchEvent {
                    observerExpectFirstFetchErrors.fulfill()

                    observerNumberTimesFirstFetching += 1

                    print("tag: \((state.requirements  as! MockOnlineRepositoryDataSource.MockGetDataRequirements).randomString!)")

                    if observerNumberTimesFirstFetching == 2 {
                        XCTAssertEqual(state.requirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, firstRequirements)
                    }
                    if observerNumberTimesFirstFetching == 3 {
                        XCTAssertEqual(state.requirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, secondRequirements)
                    }
                }
            })
            .subscribe(observer)

        fetchFreshDataSubject.onNext(FetchResponse<String>.fail(error: fetchFail))
        fetchFreshDataSubject.onCompleted()

        let observer2ExpectFirstFetchCalls = expectation(description: "observer2: Expect first fetch to call multiple times.")
        observer2ExpectFirstFetchCalls.expectedFulfillmentCount = 2
        let observer2ExpectFirstFetchErrors = expectation(description: "observer2: Expect first fetch to error for multiple calls.")
        observer2ExpectFirstFetchErrors.expectedFulfillmentCount = 2 // Must be triggered twice.

        let secondFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = secondFetchFreshDataSubject.asSingle()

        var observer2NumberTimesFirstFetching = 0

        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observer2ExpectFirstFetchCalls.fulfill()

                    observer2NumberTimesFirstFetching += 1
                }
                if state == errorFetchEvent {
                    observer2ExpectFirstFetchErrors.fulfill()
                }

                if observer2NumberTimesFirstFetching == 2 {
                    XCTAssertEqual(state.requirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, secondRequirements)
                }
            })
            .subscribe(observer2)

        secondFetchFreshDataSubject.onNext(FetchResponse<String>.fail(error: fetchFail))
        secondFetchFreshDataSubject.onCompleted()

        // Setting requirements again will change
        let thirdFetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        self.dataSource.fakeData.fetchFreshData = thirdFetchFreshDataSubject.asSingle()
        self.repository.requirements = secondRequirements

        thirdFetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchFail))
        thirdFetchFreshDataSubject.onCompleted()

        wait(for: [observerExpectFirstFetchCalls, observerExpectFirstFetchErrors,
                   observer2ExpectFirstFetchCalls, observer2ExpectFirstFetchErrors], timeout: 1.0)
    }
    
    func test_changeRequirementsToNil_resetsStateOfDataToNil() {
        let dataLastFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: dataLastFetched))
        
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just("")))
        let firstRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "first")
        initRepository(requirements: firstRequirements)

        let observeExpectCacheEmpty = expectation(description: "Expect cache to be empty right away")
        let observeExpectNoneStateAfterSetRequirementsNil = expectation(description: "Expect none data state after setting requirements to nil")

        let cacheEmptyEvent = getCacheEmptyEvent(lastTimeFetched: dataLastFetched)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == cacheEmptyEvent {
                    observeExpectCacheEmpty.fulfill()
                }
                if state == OnlineDataState<String>.none() {
                    observeExpectNoneStateAfterSetRequirementsNil.fulfill()
                }
            })
            .subscribe(observer)

        wait(for: [observeExpectCacheEmpty], timeout: 1.0)
        
        self.repository.requirements = nil

        wait(for: [observeExpectNoneStateAfterSetRequirementsNil], timeout: 1.0)
        
        XCTAssertNil(observer.events.last!.value.element!.requirements)
    }
    
    func test_deallocRepository_disposesObservers() {
        let timeFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: timeFetched))

        let observeCacheObservable: ReplaySubject<String> = ReplaySubject.createUnbounded()
        let fetchFreshDataObservable: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheObservable, fetchFreshData: fetchFreshDataObservable.asSingle())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observeExpectFirstEvent = expectation(description: "Expect this to be the first event when subscribe")
        let observeExpectToRefresh = expectation(description: "Expect observe to resfresh")
        let observeExpectToComplete = expectation(description: "Wait until dispose from completion")

        let cacheExistsNotRefreshingEvent = getCacheExistsNotRefreshingEvent(lastTimeFetched: timeFetched)
        let cacheExistsRefreshingEvent = getCacheExistsRefreshingEvent(lastTimeFetched: timeFetched)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == cacheExistsNotRefreshingEvent {
                    observeExpectFirstEvent.fulfill()
                }
                if state == cacheExistsRefreshingEvent {
                    observeExpectToRefresh.fulfill()
                }
            }, onCompleted: {
                observeExpectToComplete.fulfill()
            })
            .subscribe(observer)

        let refreshExpectToBeSkipped = expectation(description: "Expect refresh to be skipped (cancelled) after deinit")
        let refreshExpectToComplete = expectation(description: "Wait until dispose from cancel")

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.skipped(SyncResult.SkippedReason.cancelled) {
                    refreshExpectToBeSkipped.fulfill()
                }
            }, onDispose: {
                refreshExpectToComplete.fulfill()
            })
            .asObservable()
            .subscribe(refreshObserver)

        self.repository = nil

        wait(for: [observeExpectFirstEvent, observeExpectToRefresh, observeExpectToComplete,
                   refreshExpectToBeSkipped, refreshExpectToComplete], timeout: 1.0)

        observeCacheObservable.onNext("this will never get to observer")
        fetchFreshDataObservable.onNext(FetchResponse.success(data: "this will never get to observer"))
    }

    // Tests: https://github.com/levibostian/Teller-iOS/issues/20
    func test_setRequirements_immediatelyRefreshAfter() {
        let timeFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: timeFetched))

        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("data"), fetchFreshData: Single.never()))

        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider()) // Using the app schedulers provider to assert we use a background thread. Very important to test this specific bug.

        self.repository.requirements = requirements

        let exectRefreshToNotFinish = expectation(description: "Refresh should not finish")
        exectRefreshToNotFinish.isInverted = true
        let expectRefreshToNotError = expectation(description: "Refresh should not error")
        expectRefreshToNotError.isInverted = true
        let expectRefreshToNotComplete = expectation(description: "Refresh should keep running and not complete")
        expectRefreshToNotComplete.isInverted = true

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true)
            .do(onSuccess: { (syncResult) in
                exectRefreshToNotFinish.fulfill()
            }, onError: { (error) in
                expectRefreshToNotError.fulfill()
            }, onDispose: {
                expectRefreshToNotComplete.fulfill()
            })
            .asObservable()
            .subscribe(refreshObserver)

        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func test_successfulFirstFetchBeginsObservingCache() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: lastTimeDataFetched))
        let data = ""
        let fetchFreshDataSubject: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just(data), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observeExpectFirstFetch = expectation(description: "Expect first fetch after subscribe to observe")
        let observeExpectFirstFetchToSucceed = expectation(description: "Expect first fetch to succeed")
        let observeExpectCacheAfterSuccessfulFirstFetch = expectation(description: "Expect empty cache after first fetch")

        let firstFetchEvent = getFirstFetchEvent()
        let successfulFirstFetchEvent = getSuccessfulFirstFetchEvent(timeFetched: lastTimeDataFetched)
        let cacheEmptyEvent = getCacheEmptyEvent(lastTimeFetched: lastTimeDataFetched)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe()
            .do(onNext: { (state) in
                if state == firstFetchEvent {
                    observeExpectFirstFetch.fulfill()
                }
                if state == successfulFirstFetchEvent {
                    observeExpectFirstFetchToSucceed.fulfill()
                }
                if state == cacheEmptyEvent {
                    observeExpectCacheAfterSuccessfulFirstFetch.fulfill()
                }
            })
            .subscribe(observer)

        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        fetchFreshDataSubject.onNext(FetchResponse.success(data: data))
        fetchFreshDataSubject.onCompleted()

        wait(for: [observeExpectFirstFetch,
                   observeExpectFirstFetchToSucceed,
                   observeExpectCacheAfterSuccessfulFirstFetch], timeout: 1.0, enforceOrder: true)
    }
    
    func test_observeDataAlreadyFetched_doesNotNeedUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data)))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observeExpectCache = expectation(description: "Expect cache")
        let observeDoNotExpectRefresh = expectation(description: "Refresh should not happen.")
        observeDoNotExpectRefresh.isInverted = true

        let cacheDataEvent = getCacheDataEvent(lastTimeFetched: lastTimeDataFetched, cachedData: data)
        let cacheDataFetchingEvent = try! getCacheDataEvent(lastTimeFetched: lastTimeDataFetched, cachedData: data).change()
            .fetchingFreshCache()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository
            .observe()
            .do(onNext: { (state) in
                if state == cacheDataEvent {
                    observeExpectCache.fulfill()
                }
                if state == cacheDataFetchingEvent {
                    observeDoNotExpectRefresh.fulfill()
                }
            })
            .subscribe(observer)

        wait(for: [observeExpectCache], timeout: 1.0)
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func test_observeDataAlreadyFetched_needsUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        let fetchError = Fail()
        let fetchFreshDataSubject = ReplaySubject<FetchResponse<String>>.createUnbounded()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data), fetchFreshData: fetchFreshDataSubject.asSingle()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observeExpectCacheDataAndRefresh = expectation(description: "Expect cache data to exist and refresh to happen")
        let observeExpectCacheDataAndRefreshToFail = expectation(description: "Expect cache data to exist and the refresh failed")

        let cacheDataAndRefreshEvent = try! getCacheDataEvent(lastTimeFetched: lastTimeDataFetched, cachedData: data).change()
            .fetchingFreshCache()
        let cacheDataAndRefreshFailedEvent = try! getCacheDataEvent(lastTimeFetched: lastTimeDataFetched, cachedData: data).change()
            .fetchingFreshCache().change()
            .failFetchingFreshCache(fetchError)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository
            .observe()
            .do(onNext: { (state) in
                if state == cacheDataAndRefreshEvent {
                    observeExpectCacheDataAndRefresh.fulfill()
                }
                if state == cacheDataAndRefreshFailedEvent {
                    observeExpectCacheDataAndRefreshToFail.fulfill()
                }
            })
            .subscribe(observer)

        fetchFreshDataSubject.onNext(FetchResponse.fail(error: fetchError))
        fetchFreshDataSubject.onCompleted()

        wait(for: [observeExpectCacheDataAndRefresh, observeExpectCacheDataAndRefreshToFail], timeout: 1.0)
    }
    
    func test_changingRequirementsTriggersFetchIfNeverDoneBefore() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data), fetchFreshData: Single.just(FetchResponse.success(data: data))))
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        XCTAssertEqual(self.dataSource.fetchFreshDataCount, 1)
        
        self.syncStateManager.fakeData.hasEverFetchedData = false
        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        XCTAssertEqual(self.dataSource.fetchFreshDataCount, 2) // After setting requirements and having "hasEverFetchedData" having not fetched data before, we should see the fetch being called for a second time.
    }
    
    private class Fail: Error {
    }
    
}
