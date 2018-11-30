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

class OnlineRepositoryTest: XCTestCase {
    
    private var repository: OnlineRepository<MockOnlineRepositoryDataSource>!
    private var dataSource: MockOnlineRepositoryDataSource!
    private var syncStateManager: MockRepositorySyncStateManager!
    
    private var compositeDisposable: CompositeDisposable!
    
    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        
        UserDefaultsUtil.clear()
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
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: force).asObservable().subscribe(observer).dispose()
        
        XCTAssertEqual(self.dataSource.fetchFreshDataCount, 1)
        XCTAssertEqual(self.dataSource.fetchFreshDataRequirements, repository.requirements)
        XCTAssertEqual(self.dataSource.saveDataCount, 1)
        XCTAssertEqual(self.dataSource.saveDataFetchedData, data)
        XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 1)
        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.success()), Recorded.completed(0)])
    }
    
    func test_refresh_failed() {
        let errorMessage = "failed message"
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(message: errorMessage)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: true).asObservable().subscribe(observer).dispose()
        
        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.fail(FetchResponse<String>.fail(message: errorMessage).failure!)),
                                         Recorded.completed(0)])
        XCTAssertEqual(self.dataSource.saveDataCount, 0)
        XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 0)
    }
    
    func test_refresh_skipped() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: false).asObservable().subscribe(observer).dispose()

        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld)),
                                         Recorded.completed(0)])
    }

    func test_refresh_observerGetsCancelledAfterNewObserverBeginsRefresh() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single<FetchResponse<String>>.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false).asObservable().subscribe(observer)

        let observer2 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false).asObservable().subscribe(observer2)

        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.skipped(SyncResult.SkippedReason.cancelled)),
                                         Recorded.completed(0)])
    }

    func test_refresh_observerGetsCancelledAfterSettingRequirements() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: false))
        initDataSource(fakeData: getDataSourceFakeData(fetchFreshData: Single<FetchResponse<String>>.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: false).asObservable().subscribe(observer)

        self.repository.requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "new requirements")

        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.skipped(SyncResult.SkippedReason.cancelled)),
                                         Recorded.completed(0)])
    }
    
    func test_observe_firstFetch_refreshes() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: Single.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [try! OnlineDataStateStateMachine.noCacheExists(requirements: repository.requirements!).change().firstFetch()])
    }
    
    func test_observe_firstFetchFailed_butStillObserving() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)
        ])
        
        let fetchedData = "data"
        let dataLastFetched = Date()
        self.dataSource.fakeData.fetchFreshData = Single.just(FetchResponse.success(data: fetchedData))
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        self.dataSource.fakeData.observeCachedData = Observable.just(fetchedData)
        self.dataSource.fakeData.isDataEmpty = false
        self.syncStateManager.fakeData.lastTimeFetchedData = dataLastFetched
        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver).dispose()
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .successfulFirstFetch(timeFetched: dataLastFetched),
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: dataLastFetched).change()
                .cachedData(fetchedData)])
    }
    
    func test_observe_firstFetchFail_callingObserveAgainTriggersRefresh() { // After a first fetch failing, you can call refresh or observe in order to trigger an update.
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer2)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        XCTAssertRecordedElements(observer2.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
    }
    
    func test_multipleObserversOfRepository_getSameEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let observerDisposable = self.repository.observe().subscribe(observer)
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer2)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        XCTAssertRecordedElements(observer2.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        
        // Test that if 1 observer disposes, we can continue to observe changes as disposing of an observable will not dispose of the observable in the repository.
        observerDisposable.dispose()
        
        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver).dispose()
        
        XCTAssertRecordedElements(observer2.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
    }
    
    func test_multipleObserversOfRepository_changeRequirements_continueToGetNewEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        let firstRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "first")
        initRepository(requirements: firstRequirements)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer2)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        XCTAssertRecordedElements(observer2.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        
        XCTAssertEqual(observer2.events.last!.value.element!.requirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, firstRequirements)
        
        // Setting requirements again will change
        let secondRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "second")
        self.repository.requirements = secondRequirements
        
        XCTAssertRecordedElements(observer2.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail),
            OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: repository.requirements!).change()
                .firstFetch().change()
                .errorFirstFetch(error: fetchFail)])
        
        XCTAssertEqual(observer2.events.last!.value.element!.requirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, secondRequirements)
    }
    
    func test_changeRequirementsToNil_resetsStateOfDataToNil() {
        let dataLastFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: dataLastFetched))
        
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just("")))
        let firstRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: "first")
        initRepository(requirements: firstRequirements)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: firstRequirements, lastTimeFetched: dataLastFetched).change()
                .cacheIsEmpty()])
        
        self.repository.requirements = nil
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: firstRequirements, lastTimeFetched: dataLastFetched).change()
                .cacheIsEmpty(),
            OnlineDataState<String>.none()])
        
        XCTAssertNil(observer.events.last!.value.element!.requirements)
    }
    
    func test_deallocRepository_disposesObservers() {
        let timeFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: timeFetched))

        let observeCacheObservable: PublishSubject<String> = PublishSubject()
        let fetchFreshDataObservable: PublishSubject<FetchResponse<String>> = PublishSubject()
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: observeCacheObservable, fetchFreshData: fetchFreshDataObservable.asSingle())
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: requirements)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver)

        self.repository = nil

        observeCacheObservable.onNext("this will never get to observer")
        fetchFreshDataObservable.onNext(FetchResponse.success(data: "this will never get to observer"))

        XCTAssertEqual(observer.events, [
            Recorded.next(0, OnlineDataStateStateMachine<String>
                                .cacheExists(requirements: requirements, lastTimeFetched: timeFetched)),
            Recorded.next(0, try! OnlineDataStateStateMachine<String>
                .cacheExists(requirements: requirements, lastTimeFetched: timeFetched).change()
                .fetchingFreshCache()),
            Recorded.completed(0)])

        XCTAssertEqual(refreshObserver.events, [
            Recorded.next(0, SyncResult.skipped(SyncResult.SkippedReason.cancelled)),
            Recorded.completed(0)])
    }

    // This is a test case to test a bug I had at one point. Teller's OnlineDataState used to couple the fetching cache data and having the cache data state together. So, when you call refresh, it was required that there was already a cache data state set (which gets set in the OnlineRepository observing of cache data). However, because of observing cache data on a background thread, if you call refresh immediately after setting requirements, the code will fail because the cache data has never been set to this point yet.
    func test_setRequirements_immediatelyRefreshAfter() {
        let timeFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: timeFetched))

        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        initDataSource(fakeData: self.getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just("data"), fetchFreshData: Single.never()))

        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager, schedulersProvider: AppSchedulersProvider()) // Using the app schedulers provider to assert we use a background thread.

        self.repository.requirements = requirements

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver)

        // If we get here, the test is successful.
    }
    
    func test_successfulFirstFetchBeginsObservingCache() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just(""), fetchFreshData: Single.just(FetchResponse.success(data: data))))
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeDataFetched).change()
                .cacheIsEmpty()])
    }
    
    func test_observeDataAlreadyFetched_doesNotNeedUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data)))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeDataFetched).change()
                .cachedData(data)])
    }
    
    func test_observeDataAlreadyFetched_needsUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        let fetchError = Fail()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data), fetchFreshData: Single.just(FetchResponse.fail(error: fetchError))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil))
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: repository.requirements!, lastTimeFetched: lastTimeDataFetched).change()
                .cachedData(data).change()
                .fetchingFreshCache().change()
                .failFetchingFreshCache(fetchError)])
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
