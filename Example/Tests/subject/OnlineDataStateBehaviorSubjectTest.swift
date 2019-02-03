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
    private var compositeDisposable: CompositeDisposable!
    
    override func setUp() {
        super.setUp()
        
        self.subject = OnlineDataStateBehaviorSubject()
        self.compositeDisposable = CompositeDisposable()
    }
    
    override func tearDown() {
        self.compositeDisposable.dispose()
        self.compositeDisposable = nil

        super.tearDown()
    }
    
    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
    }

    func test_resetStateToNone_receiveNoDataState() {
        self.subject.resetStateToNone()

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
    }

    func test_resetToNoCacheState_receiveCorrectDataState() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataStateStateMachine.noCacheExists(requirements: requirements)])
    }

    func test_resetToCacheState_receiveCorrectDataState() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        let lastTimeFetched = Date()
        self.subject.resetToCacheState(requirements: requirements, lastTimeFetched: lastTimeFetched)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        self.subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataStateStateMachine.cacheExists(requirements: requirements, lastTimeFetched: lastTimeFetched)])
    }

    func test_changeState_sendsResultToSubject() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer)

        self.subject.changeState({ return try! $0.firstFetch() })

        XCTAssertRecordedElements(observer.events, [
            OnlineDataStateStateMachine.noCacheExists(requirements: requirements),
            try! OnlineDataStateStateMachine.noCacheExists(requirements: requirements).change().firstFetch()])
    }
    
    func test_multipleObservers_receiveDifferentNumberOfEvents() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        self.subject.resetStateToNone()
        self.subject.resetToNoCacheState(requirements: requirements)
        self.subject.changeState({ return try! $0.firstFetch() })
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer1)
        let fetched = Date()
        self.subject.changeState({ return try! $0.successfulFirstFetch(timeFetched: fetched) })
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += self.subject.subject.subscribe(observer2)
        
        let data = "foo"
        self.subject.changeState({ return try! $0.cachedData(data) })

        XCTAssertRecordedElements(observer1.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch().change()
                .successfulFirstFetch(timeFetched: fetched),
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: requirements, lastTimeFetched: fetched).change()
                .cachedData(data)])
        XCTAssertEqual(observer2.events, Array(observer1.events[1..<observer1.events.count]))
    }
    
    private class Fail: Error {
    }
    
}
