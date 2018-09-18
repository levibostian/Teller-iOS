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
    
    private var subject: OnlineDataStateBehaviorSubject<String> = OnlineDataStateBehaviorSubject()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.isEmpty()])
    }
    
    func test_onNextFirstFetchOfData() {
        self.subject.onNextFirstFetchOfData()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.firstFetchOfData()])
    }
    
    func test_onNextCacheEmpty() {
        self.subject.onNextCacheEmpty(isFetchingFreshData: true)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.isEmpty().fetchingFreshData()])
    }
    
    func test_onNextCachedData() {
        let data = "foo"
        let fetched = Date()
        self.subject.onNextCachedData(data: data, dataFetched: fetched, isFetchingFreshData: true)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.data(data: data, dataFetched: fetched).fetchingFreshData()])
    }
    
    func test_onNextDoneFetchingFreshData() {
        let error = Fail()
        self.subject.onNextDoneFetchingFreshData(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.isEmpty().doneFetchingFreshData(errorDuringFetch: error)])
    }
    
    func test_onNextFetchingFreshData() {
        self.subject.onNextFetchingFreshData()
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.isEmpty().fetchingFreshData()])
    }
    
    func test_onNextDoneFirstFetch() {
        let error = Fail()
        self.subject.onNextFirstFetchOfData()
        self.subject.onNextDoneFirstFetch(errorDuringFetch: error)
        
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.asObservable().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.firstFetchOfData().doneFirstFetch(error: error)])
    }
    
    func test_onNextEmpty_receive2Events() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        let dispose = self.subject.asObservable().subscribe(observer)
        
        self.subject.onNextFetchingFreshData()
        dispose.dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState.isEmpty(), OnlineDataState.isEmpty().fetchingFreshData()])
    }
    
    func test_multipleObservers() {
        var compositeDisposable = CompositeDisposable()
        self.subject.onNextFirstFetchOfData()
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.asObservable().subscribe(observer1)
        
        self.subject.onNextDoneFirstFetch(errorDuringFetch: nil)
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.asObservable().subscribe(observer2)
        
        let data = "foo"
        let fetched = Date()
        self.subject.onNextCachedData(data: data, dataFetched: fetched, isFetchingFreshData: false)
        compositeDisposable.dispose()
        
        XCTAssertRecordedElements(observer1.events, [OnlineDataState.firstFetchOfData(), OnlineDataState.firstFetchOfData().doneFirstFetch(error: nil), OnlineDataState.data(data: data, dataFetched: fetched)])
        XCTAssertRecordedElements(observer2.events, [OnlineDataState.firstFetchOfData().doneFirstFetch(error: nil), OnlineDataState.data(data: data, dataFetched: fetched)])
    }
    
    private class Fail: Error {
    }
    
}
