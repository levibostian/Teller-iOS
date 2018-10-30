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
    
    func test_refresh_force_successfullyRefresh() {
        let force = true
        let data = "foo"
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: Date()))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.success(data: data))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
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
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: true).asObservable().subscribe(observer).dispose()
        
        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.fail(FetchResponse<String>.fail(message: errorMessage).failure!)),
                                         Recorded.completed(0)])
        XCTAssertEqual(self.dataSource.saveDataCount, 0)
        XCTAssertEqual(self.syncStateManager.updateAgeOfDataCount, 0)
    }
    
    func test_refresh_skipped() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: false).asObservable().subscribe(observer).dispose()

        XCTAssertEqual(observer.events, [Recorded.next(0, SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld)),
                                         Recorded.completed(0)])
    }
    
    func test_observe_requirementsNotSet_throwError() {
        initRepository(requirements: nil)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        XCTAssertThrowsError(try self.repository.observe().subscribe(observer).dispose())
    }
    
    func test_observe_firstFetch_refreshes() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(hasEverFetchedData: false))
        initDataSource(fakeData: self.getDataSourceFakeData(fetchFreshData: Single.never()))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!)])
    }
    
    func test_observe_firstFetchFailed_butStillObserving() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)
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
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: nil),
            OnlineDataState<String>.data(data: fetchedData, dataFetched: dataLastFetched, getDataRequirements: repository.requirements!)])
    }
    
    func test_observe_firstFetchFail_callingObserveAgainTriggersRefresh() { // After a first fetch failing, you can call refresh or observe in order to trigger an update.
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer2)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
        XCTAssertRecordedElements(observer2.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
    }
    
    func test_multipleObserversOfRepository_getSameEvents() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let observerDisposable = try! self.repository.observe().subscribe(observer)
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer2)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
        XCTAssertRecordedElements(observer2.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
        
        // Test that if 1 observer disposes, we can continue to observe changes as disposing of an observable will not dispose of the observable in the repository.
        observerDisposable.dispose()
        
        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        try! self.repository.refresh(force: true).asObservable().subscribe(refreshObserver).dispose()
        
        XCTAssertRecordedElements(observer2.events, [
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!),
            OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail)])
    }
    
    func test_disposeRepository_disposesObservers() {
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false))
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        let fetchEvent = Recorded.next(0, OnlineDataState<String>.firstFetchOfData(getDataRequirements: repository.requirements!).doneFirstFetch(error: fetchFail))
        self.repository = nil
        
        XCTAssertEqual(observer.events, [
            fetchEvent,
            Recorded.completed(0)])
    }
    
    func test_successfulFirstFetchBeginsObservingCache() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: false, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.just(""), fetchFreshData: Single.just(FetchResponse.success(data: data))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        self.syncStateManager.updateAgeOfDataListener = { () -> Bool? in
            return true
        }
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)        
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.isEmpty(getDataRequirements: repository.requirements!, dataFetched: lastTimeDataFetched)])
    }
    
    func test_observeDataAlreadyFetched_doesNotNeedUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data)))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.data(data: data, dataFetched: lastTimeDataFetched, getDataRequirements: repository.requirements!)])
    }
    
    func test_observeDataAlreadyFetched_needsUpdated() {
        let lastTimeDataFetched = Date()
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeDataFetched))
        let data = "success"
        let fetchError = Fail()
        initDataSource(fakeData: getDataSourceFakeData(isDataEmpty: false, observeCachedData: Observable.just(data), fetchFreshData: Single.just(FetchResponse.fail(error: fetchError))))
        initRepository(requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements())
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += try! self.repository.observe().subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.data(data: data, dataFetched: lastTimeDataFetched, getDataRequirements: repository.requirements!).doneFetchingFreshData(errorDuringFetch: fetchError)])
    }
    
    private class Fail: Error {
    }
    
}
