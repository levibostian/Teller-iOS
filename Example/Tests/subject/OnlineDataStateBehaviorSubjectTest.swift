//
//  OnlineDataStateBehaviorSubjectTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Teller

class OnlineDataStateBehaviorSubjectTest: XCTestCase {

    private var subject: OnlineDataStateBehaviorSubject<String>!
    
    override func setUp() {
        super.setUp()
        
        self.subject = OnlineDataStateBehaviorSubject()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
    }
    
    func test_onNextFirstFetchOfData() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextFirstFetchOfData(requirements: requirements)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(requirements: requirements)])
    }
    
    func test_onNextCacheEmpty() {
        let fetched = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextCacheEmpty(requirements: requirements, isFetchingFreshData: true, dataFetched: fetched)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.isEmpty(requirements: requirements, dataFetched: fetched).fetchingFreshData()])
    }
    
    func test_onNextCachedData() {
        let data = "foo"
        let fetched = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextCachedData(requirements: requirements, data: data, dataFetched: fetched, isFetchingFreshData: true)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.data(data: data, dataFetched: fetched, requirements: requirements).fetchingFreshData()])
    }
    
    func test_onNextDoneFetchingFreshData() {
        let fetched = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        let error = Fail()
        self.subject.onNextCacheEmpty(requirements: requirements, isFetchingFreshData: true, dataFetched: fetched)
        self.subject.onNextDoneFetchingFreshData(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.isEmpty(requirements: requirements, dataFetched: fetched).fetchingFreshData().doneFetchingFreshData(errorDuringFetch: error)])
    }
    
    func test_onNextFetchingFreshData() {
        let fetched = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextCacheEmpty(requirements: requirements, isFetchingFreshData: true, dataFetched: fetched)
        self.subject.onNextFetchingFreshData()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.isEmpty(requirements: requirements, dataFetched: fetched).fetchingFreshData()])
    }
    
    func test_onNextDoneFirstFetch() {
        let error = Fail()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextFirstFetchOfData(requirements: requirements)
        self.subject.onNextDoneFirstFetch(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.firstFetchOfData(requirements: requirements).doneFirstFetch(error: error)])
    }
    
    func test_onNextEmpty_receive2Events() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let dispose = self.subject.subject.subscribe(observer)
        
        let fetched = Date()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.onNextCacheEmpty(requirements: requirements, isFetchingFreshData: true, dataFetched: fetched)
        dispose.dispose()
        
        XCTAssertRecordedElements(observer.events, [
            OnlineDataState<String>.none(),
            OnlineDataState<String>.isEmpty(requirements: requirements, dataFetched: fetched),
            OnlineDataState<String>.isEmpty(requirements: requirements, dataFetched: fetched).fetchingFreshData()])
    }
    
    func test_multipleObservers() {
        var compositeDisposable = CompositeDisposable()
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.resetStateToNone()
        self.subject.onNextFirstFetchOfData(requirements: requirements)
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer1)
        self.subject.onNextDoneFirstFetch(errorDuringFetch: nil)
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer2)
        
        let data = "foo"
        let fetched = Date()
        self.subject.onNextCachedData(requirements: requirements, data: data, dataFetched: fetched, isFetchingFreshData: false)
        compositeDisposable.dispose()
        
        XCTAssertRecordedElements(observer1.events, [
            OnlineDataState.firstFetchOfData(requirements: requirements),
            OnlineDataState.firstFetchOfData(requirements: requirements).doneFirstFetch(error: nil),
            OnlineDataState.data(data: data, dataFetched: fetched, requirements: requirements)])
        XCTAssertRecordedElements(observer2.events, [
            OnlineDataState<String>.firstFetchOfData(requirements: requirements).doneFirstFetch(error: nil),
            OnlineDataState<String>.data(data: data, dataFetched: fetched, requirements: requirements)])
    }
    
    private class Fail: Error {
    }
    
}
