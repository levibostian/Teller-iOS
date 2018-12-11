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

    func test_multipleRefreshRequests_shareSameRefreshObserver() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let expectDelegateRefreshComplete = expectation(description: "Expect manager delegate refresh success after fetch response comes in.")

        let delegate = MockOnlineRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            expectDelegateRefreshComplete.fulfill()
        }

        self.refreshManager.delegate = delegate

        let observer1RefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let ignoredFailedFetchResponseError = Fail()

        let expectObserver1ToSubscribeToRefresh = expectation(description: "Expect observer1 to subscribe to refresh.")
        let expectObserver1ToReceiveRefreshResultSuccessfulEvent = expectation(description: "Expect observer1 to receive successful sync result after fetch.")
        let doNotExpectObserver1ReceiveRefreshResultFailedEvent = expectation(description: "Expect observer1 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver1ReceiveRefreshResultFailedEvent.isInverted = true
        let expectObserver1ToComplete = expectation(description: "Expect observer1 to complete refresh after fetch response back.")

        let observer1 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer1RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                if refreshResult == RefreshResult.success() {
                    expectObserver1ToReceiveRefreshResultSuccessfulEvent.fulfill()
                }
                if refreshResult == RefreshResult.fail(ignoredFailedFetchResponseError) {
                    doNotExpectObserver1ReceiveRefreshResultFailedEvent.fulfill()
                }
            }, onSubscribe: {
                expectObserver1ToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserver1ToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer1)

        let observer2RefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded() // Will get ignored.

        let expectObserver2ToSubscribeToRefresh = expectation(description: "Expect observer2 to subscribe to refresh.")
        let expectObserver2ToReceiveRefreshResultSuccessfulEvent = expectation(description: "Expect observer2 to receive successful sync result after fetch.")
        let doNotExpectObserver2ReceiveRefreshResultFailedEvent = expectation(description: "Expect observer2 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver2ReceiveRefreshResultFailedEvent.isInverted = true
        let expectObserver2ToComplete = expectation(description: "Expect observer2 to complete refresh after fetch response back.")

        let observer2 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer2RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { (refreshResult) in
                if refreshResult == RefreshResult.success() {
                    expectObserver2ToReceiveRefreshResultSuccessfulEvent.fulfill()
                }
                if refreshResult == RefreshResult.fail(ignoredFailedFetchResponseError) {
                    doNotExpectObserver2ReceiveRefreshResultFailedEvent.fulfill()
                }
            }, onSubscribe: {
                expectObserver2ToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserver2ToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer2)

        wait(for: [expectDelegateRefreshBegin,
                   expectObserver1ToSubscribeToRefresh,
                   expectObserver2ToSubscribeToRefresh], timeout: 0.5) // Wait for refresh subscriptions.

        let fetchResponseData = "success"
        observer1RefreshTask.onNext(FetchResponse.success(data: fetchResponseData))
        observer1RefreshTask.onCompleted()

        // This will be ignored. The first refresh task will be the one used.
        observer2RefreshTask.onNext(FetchResponse.fail(error: ignoredFailedFetchResponseError))
        observer2RefreshTask.onCompleted()

        waitForExpectations(timeout: 0.2, handler: nil)
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
                if refreshResult == RefreshResult.success() {
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
        observer1RefreshTask.onNext(FetchResponse.success(data: fetchResponseData))
        observer1RefreshTask.onCompleted()

        wait(for: [expectObserver1ToSubscribeToRefresh,
                   expectObserver1ToReceiveRefreshResultSuccessfulEvent,
                   expectObserver1ToComplete], timeout: 0.2)

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
                if refreshResult == RefreshResult.success() {
                    doNotExpectObserver2ReceiveRefreshResultSuccessfulEvent.fulfill()
                }
                if refreshResult.didFail() && refreshResult.failedError is Fail {
                    expectObserver2ToReceiveRefreshResultFailedEvent.fulfill()
                }
            }, onSubscribe: {
                expectObserver2ToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserver2ToComplete.fulfill()
            })
            .asObservable()
            .subscribe(observer2)

        observer2RefreshTask.onNext(FetchResponse.fail(error: fetchResponseError))
        observer2RefreshTask.onCompleted()

        waitForExpectations(timeout: 0.5, handler: nil)
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
                if refreshResult == RefreshResult.skipped(.cancelled) {
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
                   expectObserverToSubscribeToRefresh], timeout: 0.2)

        self.refreshManager.cancelRefresh()
        wait(for: [expectObserverToReceiveRefreshResultSkippedEvent], timeout: 0.2) // Because cancelRefresh() call is running async, we need to wait for that event to happen.

        // These should be ignored
        let fetchResponseData = "success"
        observerRefreshTask.onNext(FetchResponse.success(data: fetchResponseData))
        observerRefreshTask.onCompleted()

        waitForExpectations(timeout: 0.5, handler: nil)
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
                if refreshResult == RefreshResult.skipped(RefreshResult.SkippedReason.cancelled) {
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
                   expectObserverToSubscribeToRefresh], timeout: 0.2)

        // Cancel refresh manager from a unique thread to test that we can cancel from any thread and it's still safe.
        DispatchQueue(label: "random", qos: .background).sync {
            self.refreshManager = nil
        }

        // These should be ignored
        let fetchResponseData = "success"
        observerRefreshTask.onNext(FetchResponse.success(data: fetchResponseData))
        observerRefreshTask.onCompleted()

        waitForExpectations(timeout: 0.5, handler: nil)
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

        observerRefreshTask.onNext(FetchResponse<String>.success(data: "cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectDelegateRefreshBegin,
                   expectDelegateRefreshComplete], timeout: 0.2, enforceOrder: true)
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
                if refreshResult == RefreshResult.success() {
                    expectObserverToReceiveResultSuccessful.fulfill()
                }
            }, onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserverToComplete.fulfill()
            })
            .subscribe(observer)

        observerRefreshTask.onNext(FetchResponse<String>.success(data: "cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectObserverToSubscribeToRefresh,
                   expectObserverToReceiveResultSuccessful,
                   expectObserverToComplete], timeout: 0.5, enforceOrder: true)
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

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    class Fail: Error {
    }

}
