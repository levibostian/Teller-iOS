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
        let expectObserver1ToReceiveSyncResultSuccessfulEvent = expectation(description: "Expect observer1 to receive successful sync result after fetch.")
        let doNotExpectObserver1ReceiveSyncResultFailedEvent = expectation(description: "Expect observer1 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver1ReceiveSyncResultFailedEvent.isInverted = true
        let expectObserver1ToComplete = expectation(description: "Expect observer1 to complete refresh after fetch response back.")

        let observer1 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer1RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .debug("ob1", trimOutput: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    expectObserver1ToReceiveSyncResultSuccessfulEvent.fulfill()
                }
                if syncResult == SyncResult.fail(ignoredFailedFetchResponseError) {
                    doNotExpectObserver1ReceiveSyncResultFailedEvent.fulfill()
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
        let expectObserver2ToReceiveSyncResultSuccessfulEvent = expectation(description: "Expect observer2 to receive successful sync result after fetch.")
        let doNotExpectObserver2ReceiveSyncResultFailedEvent = expectation(description: "Expect observer2 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver2ReceiveSyncResultFailedEvent.isInverted = true
        let expectObserver2ToComplete = expectation(description: "Expect observer2 to complete refresh after fetch response back.")

        let observer2 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer2RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .debug("ob2", trimOutput: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    expectObserver2ToReceiveSyncResultSuccessfulEvent.fulfill()
                }
                if syncResult == SyncResult.fail(ignoredFailedFetchResponseError) {
                    doNotExpectObserver2ReceiveSyncResultFailedEvent.fulfill()
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
        let expectObserver1ToReceiveSyncResultSuccessfulEvent = expectation(description: "Expect observer1 to receive successful sync result after fetch.")
        let doNotExpectObserver1ReceiveSyncResultFailedEvent = expectation(description: "Expect observer1 to *not* receive a failed sync result after fetch.")
        doNotExpectObserver1ReceiveSyncResultFailedEvent.isInverted = true
        let expectObserver1ToComplete = expectation(description: "Expect observer1 to complete refresh after fetch response back.")

        let observer1 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer1RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .debug("ob1", trimOutput: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    expectObserver1ToReceiveSyncResultSuccessfulEvent.fulfill()
                } else {
                    doNotExpectObserver1ReceiveSyncResultFailedEvent.fulfill()
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
                   expectObserver1ToReceiveSyncResultSuccessfulEvent,
                   expectObserver1ToComplete], timeout: 0.2)

        let observer2RefreshTask: ReplaySubject<FetchResponse<String>> = ReplaySubject.createUnbounded()

        let fetchResponseError = Fail()

        let expectObserver2ToSubscribeToRefresh = expectation(description: "Expect observer2 to subscribe to refresh.")
        let expectObserver2ToReceiveSyncResultFailedEvent = expectation(description: "Expect observer2 to receive failed sync result after fetch.")
        let doNotExpectObserver2ReceiveSyncResultSuccessfulEvent = expectation(description: "Expect observer2 to *not* receive a successful sync result after fetch.")
        doNotExpectObserver2ReceiveSyncResultSuccessfulEvent.isInverted = true
        let expectObserver2ToComplete = expectation(description: "Expect observer2 to complete refresh after fetch response back.")

        let observer2 = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observer2RefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .debug("ob2", trimOutput: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.success() {
                    doNotExpectObserver2ReceiveSyncResultSuccessfulEvent.fulfill()
                }
                if syncResult.didFail() && syncResult.failedError is Fail {
                    expectObserver2ToReceiveSyncResultFailedEvent.fulfill()
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
        let expectObserverToReceiveSyncResultSkippedEvent = expectation(description: "Expect observer to receive fetch response to be skipped.")
        let doNotExpectObserverToReceiveOtherSyncResults = expectation(description: "Expect observer to *not* receive any refresh results except for being skipped.")
        doNotExpectObserverToReceiveOtherSyncResults.isInverted = true
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after manager is deinit.")

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .debug("ob1", trimOutput: false)
            .do(onSuccess: { (syncResult) in
                if syncResult == SyncResult.skipped(SyncResult.SkippedReason.cancelled) {
                    expectObserverToReceiveSyncResultSkippedEvent.fulfill()
                } else {
                    doNotExpectObserverToReceiveOtherSyncResults.fulfill()
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

        // Set refresh manager from a unique thread to test that multi-threading of deinit
        DispatchQueue(label: "random", qos: .background).sync {
            self.refreshManager = nil
        }

        XCTAssertNil(self.refreshManager)

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

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
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

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .debug("obs", trimOutput: false)
            .asObservable()
            .do(onNext: { (syncResult) in
                if syncResult == SyncResult.success() {
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

    // Because we are asynchronously calling delegate functions on main thread, there is a delay when those messages are sent to the main thread.
    // I want to create a test that asserts that the delegate function does not get called after deinit of refresh manager which means that we are not holding a strong reference in the `async` call.
    func test_delegateNotUpdatedAfterRefreshManagerDeinit() {
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

        let observer = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
        compositeDisposable += self.refreshManager.refresh(task: observerRefreshTask.asSingle())
            .debug("obs", trimOutput: false)
            .asObservable()
            .do(onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            })
            .subscribe(observer)

        wait(for: [expectDelegateRefreshBegin, expectObserverToSubscribeToRefresh], timeout: 0.2)

        observerRefreshTask.onNext(FetchResponse<String>.success(data: "cache"))
        observerRefreshTask.onCompleted()
        // The main thread async call is probably scheduled now.

        self.refreshManager = nil // Because setting to nil on same thread, synchronously, the async delegate call should not run in the refresh manager.

        waitForExpectations(timeout: 0.3, handler: nil)
    }

    func test_refresh_failureGetsPassedOn() {
        let expectRefreshObserverToReceiveError = expectation(description: "Expect observer to receive error from fetch")
        let expectRefreshObserverToDispose = expectation(description: "Expct observer to dispose after error received.")

        let refreshTask: PublishSubject<FetchResponse<String>> = PublishSubject()

        let fetchFail = Fail()

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(SyncResult.self)
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

    class MockOnlineRepositoryRefreshManagerDelegate: OnlineRepositoryRefreshManagerDelegate {
        var invokedRefreshBegin = false
        var invokedRefreshBeginCount = 0
        var invokedRefreshBeginThen: (() -> Void)? = nil
        func refreshBegin() {
            invokedRefreshBegin = true
            invokedRefreshBeginCount += 1
            invokedRefreshBeginThen?()
        }
        var invokedRefreshComplete = false
        var invokedRefreshCompleteCount = 0
        var invokedRefreshCompleteThen: (() -> Void)? = nil
        func refreshComplete<String>(_ response: FetchResponse<String>) {
            invokedRefreshComplete = true
            invokedRefreshCompleteCount += 1
            invokedRefreshCompleteThen?()
        }
    }

    class Fail: Error {
    }

}
