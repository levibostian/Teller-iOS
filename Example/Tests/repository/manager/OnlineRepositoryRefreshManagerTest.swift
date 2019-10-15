//
//  OnlineRepositoryRefreshManagerTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 12/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RxTest
@testable import Teller

class OnlineRepositoryRefreshManagerTest: XCTestCase {

    private var refreshManager: AppOnlineRepositoryRefreshManager<String>!

    private let schedulersProvider = TestsSchedulersProvider()

    private var compositeDisposable = CompositeDisposable()

    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        self.refreshManager = AppOnlineRepositoryRefreshManager<String>()
    }

    override func tearDown() {
        super.tearDown()

        compositeDisposable.dispose()
    }

    // Tests that the refresh() function that returns an Observer is thread safe in that only creates a new Observer and starts a new refresh task when another one is not running.
    func test_multipleCallsToGetRefreshTask_resultInSameObserver() {
        // If the refresh() function does share the same observer, only 1 of the refresh tasks passed in will be observed. Not both which means that each of the refresh fetch tasks passed in were started.
        let expectOnlyOneRefreshTaskToBeObserved = expectation(description: "Expect one of the refresh tasks to be observed")
        expectOnlyOneRefreshTaskToBeObserved.expectedFulfillmentCount = 1
        expectOnlyOneRefreshTaskToBeObserved.assertForOverFulfill = true

        let observer1RefreshTask: Single<FetchResponse<String>> = ReplaySubject.createUnbounded()
            .asSingle()
            .do(onSubscribe: {
                expectOnlyOneRefreshTaskToBeObserved.fulfill()
            })

        let observer1 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        let observer2 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)

        let observer2RefreshTask: Single<FetchResponse<String>> = ReplaySubject.createUnbounded()
            .asSingle()
            .do(onSubscribe: {
                expectOnlyOneRefreshTaskToBeObserved.fulfill()
            })

        // We do not know which of the 2 async background threads will be executed first. That's why we only have 1 expectation above shared between both of the `observerXrefreshTask`s because either one could be subscribed to depending on the order below.
        DispatchQueue(label: "observer1").async {
            let observer1RefreshManagerRefresh = self.refreshManager.refresh(task: observer1RefreshTask)

            self.compositeDisposable += observer1RefreshManagerRefresh
                .asObservable()
                .subscribe(observer1)
        }
        DispatchQueue(label: "observer2").async {
            let observer2RefreshManagerRefresh = self.refreshManager.refresh(task: observer2RefreshTask)

            self.compositeDisposable += observer2RefreshManagerRefresh
                .asObservable()
                .subscribe(observer2)
        }

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_newRefreshBeginsAfterPreviousOneComplete() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        expectDelegateRefreshBegin.expectedFulfillmentCount = 2
        let expectDelegateRefreshComplete = expectation(description: "Expect manager delegate refresh success after fetch response comes in.")
        expectDelegateRefreshComplete.expectedFulfillmentCount = 2

        let delegate = MockOnlineRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            expectDelegateRefreshComplete.fulfill()
        }

        self.refreshManager.delegate = delegate

        let observer1RefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let expectObserver1ToSubscribeToRefresh = expectation(description: "Expect observer1 to subscribe to refresh observer.")
        let expectObserver1ToReceiveRefreshResultSuccessfulEvent = expectation(description: "Expect observer1 to receive successful sync result after fetch.")
        let doNotExpectObserver1ReceiveRefreshResultFailedEvent = expectation(description: "Expect observer1 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver1ReceiveRefreshResultFailedEvent.isInverted = true
        let expectObserver1ToComplete = expectation(description: "Expect observer1 to complete refresh after fetch response back.")

        let observer1 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer1RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                if refreshResult == .successful {
                    expectObserver1ToReceiveRefreshResultSuccessfulEvent.fulfill()
                } else {
                    doNotExpectObserver1ReceiveRefreshResultFailedEvent.fulfill()
                }
            }, onSubscribe: {
                expectObserver1ToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserver1ToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer1)

        let fetchResponseData = "success"
        observer1RefreshTask.onNext(FetchResponse.success(fetchResponseData))
        observer1RefreshTask.onCompleted()

        wait(for: [expectObserver1ToSubscribeToRefresh,
                   expectObserver1ToReceiveRefreshResultSuccessfulEvent,
                   expectObserver1ToComplete], timeout: TestConstants.AWAIT_DURATION)

        let observer2RefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let fetchResponseError = Fail()

        let expectObserver2ToSubscribeToRefresh = expectation(description: "Expect observer2 to subscribe to refresh.")
        let expectObserver2ToReceiveRefreshResultFailedEvent = expectation(description: "Expect observer2 to receive failed sync result after fetch.")
        let doNotExpectObserver2ReceiveRefreshResultSuccessfulEvent = expectation(description: "Expect observer2 to *not* receive a successful sync result after fetch.")
        doNotExpectObserver2ReceiveRefreshResultSuccessfulEvent.isInverted = true
        let expectObserver2ToComplete = expectation(description: "Expect observer2 to complete refresh after fetch response back.")

        let observer2 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer2RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                switch refreshResult {
                case .successful:
                    doNotExpectObserver2ReceiveRefreshResultSuccessfulEvent.fulfill()
                case .failedError(let failedError):
                    if failedError is Fail {
                        expectObserver2ToReceiveRefreshResultFailedEvent.fulfill()
                    }
                default: break
                }
            }, onSubscribe: {
                expectObserver2ToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserver2ToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer2)

        observer2RefreshTask.onNext(FetchResponse.failure(fetchResponseError))
        observer2RefreshTask.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cancel_refreshTaskGetsCancelled() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let doNotExpectDelegateRefreshComplete = expectation(description: "Do not expect manager delegate refresh success to call.")
        doNotExpectDelegateRefreshComplete.isInverted = true

        let delegate = MockOnlineRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            doNotExpectDelegateRefreshComplete.fulfill()
        }

        self.refreshManager.delegate = delegate

        let observerRefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveRefreshResultSkippedEvent = expectation(description: "Expect observer to receive fetch response to be skipped.")
        let doNotExpectObserverToReceiveOtherRefreshResults = expectation(description: "Expect observer to *not* receive any refresh results except for being skipped.")
        doNotExpectObserverToReceiveOtherRefreshResults.isInverted = true
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after manager is cancelled.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                if refreshResult == .skipped(reason: .cancelled) {
                    expectObserverToReceiveRefreshResultSkippedEvent.fulfill()
                } else {
                    doNotExpectObserverToReceiveOtherRefreshResults.fulfill()
                }
            }, onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserverToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        wait(for: [expectDelegateRefreshBegin,
                   expectObserverToSubscribeToRefresh], timeout: TestConstants.AWAIT_DURATION)

        self.refreshManager.cancelRefresh()
        wait(for: [expectObserverToReceiveRefreshResultSkippedEvent], timeout: TestConstants.AWAIT_DURATION) // Because cancelRefresh() call is running async, we need to wait for that event to happen.

        // These should be ignored
        let fetchResponseData = "success"
        observerRefreshTask.onNext(FetchResponse.success(fetchResponseData))
        observerRefreshTask.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_deinit_refreshTaskGetsCancelled() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let doNotExpectDelegateRefreshComplete = expectation(description: "Do not expect manager delegate refresh success to call.")
        doNotExpectDelegateRefreshComplete.isInverted = true

        let delegate = MockOnlineRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            doNotExpectDelegateRefreshComplete.fulfill()
        }

        self.refreshManager.delegate = delegate

        let observerRefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveRefreshResultSkippedEvent = expectation(description: "Expect observer to receive fetch response to be skipped.")
        let doNotExpectObserverToReceiveOtherRefreshResults = expectation(description: "Expect observer to *not* receive any refresh results except for being skipped.")
        doNotExpectObserverToReceiveOtherRefreshResults.isInverted = true
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after manager is cancelled.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                if refreshResult == .skipped(reason: .cancelled) {
                    expectObserverToReceiveRefreshResultSkippedEvent.fulfill()
                } else {
                    doNotExpectObserverToReceiveOtherRefreshResults.fulfill()
                }
            }, onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserverToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer)

        wait(for: [expectDelegateRefreshBegin,
                   expectObserverToSubscribeToRefresh], timeout: TestConstants.AWAIT_DURATION)

        // Cancel refresh manager from a unique thread to test that we can cancel from any thread and it's still safe.
        DispatchQueue(label: "random", qos: .background).sync {
            self.refreshManager = nil
        }

        // These should be ignored
        let fetchResponseData = "success"
        observerRefreshTask.onNext(FetchResponse.success(fetchResponseData))
        observerRefreshTask.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_refresh_delegateCallsInCorrectOrder_andMainThread() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let expectDelegateRefreshComplete = expectation(description: "Expect manager delegate refresh success to call.")

        let delegate = MockOnlineRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            XCTAssertTrue(Thread.isMainThread)
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            XCTAssertTrue(Thread.isMainThread)
            expectDelegateRefreshComplete.fulfill()
        }
        self.refreshManager.delegate = delegate

        let observerRefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .asObservable()
            .subscribe(observer)

        observerRefreshTask.onNext(FetchResponse<String>.success("cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectDelegateRefreshBegin,
                   expectDelegateRefreshComplete], timeout: TestConstants.AWAIT_DURATION, enforceOrder: true)
    }

    func test_refresh_observerCallsInCorrectOrder() {
        let observerRefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveResultSuccessful = expectation(description: "Expect observer to receive fetch response to be successful.")
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after fetch call complete.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .asObservable()
            .do(onNext: { (refreshResult) in
                if refreshResult == .successful {
                    expectObserverToReceiveResultSuccessful.fulfill()
                }
            }, onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserverToComplete.fulfill()
            })
            .subscribe(observer)

        observerRefreshTask.onNext(FetchResponse<String>.success("cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectObserverToSubscribeToRefresh,
                   expectObserverToReceiveResultSuccessful,
                   expectObserverToComplete], timeout: TestConstants.AWAIT_DURATION, enforceOrder: true)
    }

    func test_refresh_failureGetsPassedOn() {
        let expectRefreshObserverToReceiveError = expectation(description: "Expect observer to receive error from fetch")
        let expectRefreshObserverToDispose = expectation(description: "Expct observer to dispose after error received.")

        let refreshTask: PublishSubject<FetchResponse<String>> = PublishSubject()

        let fetchFail = Fail()

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: refreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onError: { (error) in
                if error is Fail {
                    expectRefreshObserverToReceiveError.fulfill()
                }
            }, onDispose: {
                expectRefreshObserverToDispose.fulfill()
            })
            .asObservable()
            .subscribe(refreshObserver)

        refreshTask.onError(fetchFail)

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    class Fail: Error {
    }

}
