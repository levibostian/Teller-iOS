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

    var getDataRequirements: OnlineRepositoryGetDataRequirements!
    private var subject: OnlineDataStateBehaviorSubject<String>!
    
    override func setUp() {
        super.setUp()
        
        self.getDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject = OnlineDataStateBehaviorSubject(getDataRequirements: getDataRequirements)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none(getDataRequirements: getDataRequirements)])
    }
    
    func test_onNextFirstFetchOfData() {
        self.subject.onNextFirstFetchOfData()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: getDataRequirements)])
    }
    
    func test_onNextCacheEmpty() {
        let fetched = Date()
        self.subject.onNextCacheEmpty(isFetchingFreshData: true, dataFetched: fetched)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.isEmpty(getDataRequirements: getDataRequirements, dataFetched: fetched).fetchingFreshData()])
    }
    
    func test_onNextCachedData() {
        let data = "foo"
        let fetched = Date()
        self.subject.onNextCachedData(data: data, dataFetched: fetched, isFetchingFreshData: true)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.data(data: data, dataFetched: fetched, getDataRequirements: getDataRequirements).fetchingFreshData()])
    }
    
    func test_onNextDoneFetchingFreshData() {
        let error = Fail()
        self.subject.onNextDoneFetchingFreshData(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none(getDataRequirements: getDataRequirements).doneFetchingFreshData(errorDuringFetch: error)])
    }
    
    func test_onNextFetchingFreshData() {
        self.subject.onNextFetchingFreshData()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none(getDataRequirements: getDataRequirements).fetchingFreshData()])
    }
    
    func test_onNextDoneFirstFetch() {
        let error = Fail()
        self.subject.onNextFirstFetchOfData()
        self.subject.onNextDoneFirstFetch(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: getDataRequirements).doneFirstFetch(error: error)])
    }
    
    func test_onNextEmpty_receive2Events() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let dispose = self.subject.subject.subscribe(observer)
        
        self.subject.onNextFetchingFreshData()
        dispose.dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none(getDataRequirements: getDataRequirements), OnlineDataState<String>.none(getDataRequirements: getDataRequirements).fetchingFreshData()])
    }
    
    func test_multipleObservers() {
        var compositeDisposable = CompositeDisposable()
        self.subject.onNextFirstFetchOfData()
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer1)
        self.subject.onNextDoneFirstFetch(errorDuringFetch: nil)
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer2)
        
        let data = "foo"
        let fetched = Date()
        self.subject.onNextCachedData(data: data, dataFetched: fetched, isFetchingFreshData: false)
        compositeDisposable.dispose()
        
        XCTAssertRecordedElements(observer1.events, [OnlineDataState.firstFetchOfData(getDataRequirements: getDataRequirements), OnlineDataState.firstFetchOfData(getDataRequirements: getDataRequirements).doneFirstFetch(error: nil), OnlineDataState.data(data: data, dataFetched: fetched, getDataRequirements: getDataRequirements)])
        XCTAssertRecordedElements(observer2.events, [OnlineDataState<String>.firstFetchOfData(getDataRequirements: getDataRequirements).doneFirstFetch(error: nil), OnlineDataState<String>.data(data: data, dataFetched: fetched, getDataRequirements: getDataRequirements)])
    }
    
    private class Fail: Error {
    }
    
}
