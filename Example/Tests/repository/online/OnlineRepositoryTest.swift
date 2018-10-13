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
    
    override func setUp() {
        super.setUp()

        UserDefaultsUtil.clear()
        initDataSource(fakeData: self.getDataSourceFakeData())
        initSyncStateManager(syncStateManagerFakeData: getSyncStateManagerFakeData())
        initRepository()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func getDataSourceFakeData(isDataEmpty: Bool = false, observeCachedData: Observable<String> = Observable.empty(), fetchFreshData: Single<FetchResponse<String>> = Single.never()) -> MockOnlineRepositoryDataSource.FakeData {
        return MockOnlineRepositoryDataSource.FakeData(isDataEmpty: isDataEmpty, observeCachedData: observeCachedData, fetchFreshData: fetchFreshData)
    }
    
    private func getSyncStateManagerFakeData(isDataTooOld: Bool = false, hasEverFetchedData: Bool = false, lastTimeFetchedData: Date? = nil) -> MockRepositorySyncStateManager.FakeData {
        return MockRepositorySyncStateManager.FakeData(isDataTooOld: isDataTooOld, hasEverFetchedData: hasEverFetchedData, lastTimeFetchedData: lastTimeFetchedData)
    }
    
    private func initDataSource(fakeData: MockOnlineRepositoryDataSource.FakeData, maxAgeOfData: Period = Period(unit: 1, component: Calendar.Component.second)) {
        self.dataSource = MockOnlineRepositoryDataSource(fakeData: fakeData, maxAgeOfData: maxAgeOfData)
    }
    
    private func initSyncStateManager(syncStateManagerFakeData: MockRepositorySyncStateManager.FakeData) {
        self.syncStateManager = MockRepositorySyncStateManager(fakeData: syncStateManagerFakeData)
    }
    
    private func initRepository() {
        self.repository = OnlineRepository(dataSource: self.dataSource, syncStateManager: self.syncStateManager)
    }
    
    func test_sync_viaForce_successfullySyncs() {
        let force = true
        let data = "foo"
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.success(data: data)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        self.repository.sync(loadDataRequirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(), force: force).asObservable().subscribe(observer).dispose()
        
        XCTAssertEqual(self.dataSource.fetchFreshDataCount, 1)
        XCTAssertEqual(self.dataSource.saveDataCount, 1)
        XCTAssertEqual(self.syncStateManager.updateLastTimeFreshDataFetchedCount, 1)
        XCTAssertEqual(observer.events, [next(0, SyncResult.success()), completed(0)])
    }
    
    func test_sync_failed() {
        let errorMessage = "failed message"
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.just(FetchResponse.fail(message: errorMessage)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        self.repository.sync(loadDataRequirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(), force: true).asObservable().subscribe(observer).dispose()
        
        XCTAssertEqual(observer.events, [next(0, SyncResult.fail(FetchResponse<String>.fail(message: errorMessage).failure!)),
                                         completed(0)])
        XCTAssertEqual(self.dataSource.saveDataCount, 0)
        XCTAssertEqual(self.syncStateManager.updateLastTimeFreshDataFetchedCount, 0)
    }
    
    func test_sync_skipped() {
        let force = false
        let syncStateManagerFakeData = getSyncStateManagerFakeData(isDataTooOld: false)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        self.repository.sync(loadDataRequirements: MockOnlineRepositoryDataSource.MockGetDataRequirements(), force: force).asObservable().subscribe(observer).dispose()

        XCTAssertEqual(observer.events, [next(0, SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld)),
                                         completed(0)])
    }
    
    func test_observe_firstFetch_syncing() {
        let syncStateManagerFakeData = getSyncStateManagerFakeData(hasEverFetchedData: false)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let dataSourceFakeData = self.getDataSourceFakeData(fetchFreshData: Single.never())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: loadDataRequirements)])
    }
    
    func test_observe_firstFetch_failed() {
        let syncStateManagerFakeData = getSyncStateManagerFakeData(hasEverFetchedData: false)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let fetchFail = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.empty(), fetchFreshData: Single.just(FetchResponse.fail(error: fetchFail)).do(onSubscribe: {
            // To begin observing cached data, we need to make sure that we have fetched data before.
            self.syncStateManager.fakeData.hasEverFetchedData = true
        }))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: loadDataRequirements).doneFirstFetch(error: fetchFail)])
    }
    
    func test_observe_successfulBeginFetchingFreshData() {
        let lastTimeFetchedData = Date()
        let syncStateManagerFakeData = getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeFetchedData)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let data = "foo"
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: data.isEmpty, observeCachedData: Observable.create({ (sub) -> Disposable in
            sub.onNext(data)
            return Disposables.create()
        }), fetchFreshData: Single.never())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.data(data: data, dataFetched: lastTimeFetchedData, getDataRequirements: loadDataRequirements).fetchingFreshData()])
    }
    
    func test_observe_cacheEmpty() {
        let lastTimeFetchedData = Date()
        let syncStateManagerFakeData = getSyncStateManagerFakeData(isDataTooOld: false, hasEverFetchedData: true, lastTimeFetchedData: lastTimeFetchedData)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: true, observeCachedData: Observable.empty())
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.isEmpty(getDataRequirements: loadDataRequirements)])
    }
    
    func test_observe_successfulFetch() {
        let lastTimeFetchedData = Date()
        let syncStateManagerFakeData = getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeFetchedData)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let data = "foo"
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: data.isEmpty, observeCachedData: Observable.create({ (sub) -> Disposable in
            sub.onNext(data)
            return Disposables.create()
        }), fetchFreshData: Single.just(FetchResponse.success(data: "")))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.data(data: data, dataFetched: lastTimeFetchedData, getDataRequirements: loadDataRequirements).doneFetchingFreshData(errorDuringFetch: nil)])
    }
    
    func test_observe_failedFetch() {
        let lastTimeFetchedData = Date()
        let syncStateManagerFakeData = getSyncStateManagerFakeData(isDataTooOld: true, hasEverFetchedData: true, lastTimeFetchedData: lastTimeFetchedData)
        initSyncStateManager(syncStateManagerFakeData: syncStateManagerFakeData)
        
        let data = "foo"
        let fetchError = Fail()
        let dataSourceFakeData = self.getDataSourceFakeData(isDataEmpty: data.isEmpty, observeCachedData: Observable.create({ (sub) -> Disposable in
            sub.onNext(data)
            return Disposables.create()
        }), fetchFreshData: Single.just(FetchResponse.fail(error: fetchError)))
        initDataSource(fakeData: dataSourceFakeData)
        initRepository()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let loadDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
        self.repository.observe(loadDataRequirements: loadDataRequirements).subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.data(data: data, dataFetched: lastTimeFetchedData, getDataRequirements: loadDataRequirements).doneFetchingFreshData(errorDuringFetch: fetchError)])
    }
    
    private class Fail: Error {
    }
    
}
