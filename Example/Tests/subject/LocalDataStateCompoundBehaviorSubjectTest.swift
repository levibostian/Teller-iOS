//
//  LocalDataStateCompoundBehaviorSubjectTEst.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Teller

class LocalDataStateCompoundBehaviorSubjectTest: XCTestCase {
    
    private var subject: LocalDataStateCompoundBehaviorSubject<String> = LocalDataStateCompoundBehaviorSubject()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        // Assert that isEmpty() is set on init()
        XCTAssertRecordedElements(observer.events, [LocalDataState.none()])
    }
    
    func test_onNextEmpty_receive1Event() {
        self.subject.onNextEmpty()
        
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        let dispose = self.subject.subject.subscribe(observer)
        
        dispose.dispose()
        
        // We should only be receiving 1 event because I am subscribing *after* I am calling onNextEmpty().
        XCTAssertRecordedElements(observer.events, [LocalDataState.isEmpty()])
    }
    
    func test_onNextEmpty_receive2Events() {
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        let dispose = self.subject.subject.subscribe(observer)

        self.subject.onNextEmpty()
        dispose.dispose()
        
        // Receive 2 events because I am subscribing *before* I call onNextEmpty().
        XCTAssertRecordedElements(observer.events, [LocalDataState.none(), LocalDataState.isEmpty()])
    }
    
    func test_multipleObservers() {
        var compositeDisposable = CompositeDisposable()
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer1)

        self.subject.onNextEmpty()
        
        let observer2 = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer2)
        
        let data = "foo"
        self.subject.onNextData(data: data)
        compositeDisposable.dispose()
        
        XCTAssertRecordedElements(observer1.events, [LocalDataState.none(), LocalDataState.isEmpty(), LocalDataState.data(data: data)])
        XCTAssertRecordedElements(observer2.events, [LocalDataState.isEmpty(), LocalDataState.data(data: data)])
    }
    
    func test_onNextData() {
        var compositeDisposable = CompositeDisposable()
        
        let data = "foo"
        self.subject.onNextData(data: data)
        
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer)
        
        XCTAssertRecordedElements(observer.events, [LocalDataState.data(data: data)])
    }
    
    func test_resetStateToNone() {
        var compositeDisposable = CompositeDisposable()
        
        let data = "foo"
        self.subject.onNextData(data: data)
        
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer)
        
        self.subject.resetStateToNone()
        
        XCTAssertRecordedElements(observer.events, [LocalDataState.data(data: data), LocalDataState.none()])
    }
    
}
