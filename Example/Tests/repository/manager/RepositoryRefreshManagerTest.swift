import Foundation
import RxSwift
import RxTest
@testable import Teller
import XCTest

class RepositoryRefreshManagerTest: XCTestCase {
    private var refreshManager: AppRepositoryRefreshManager!

    private let schedulersProvider = TestsSchedulersProvider()

    private let defaultRequirements = MockRepositoryDataSource.Requirements(randomString: nil)

    private var compositeDisposable = CompositeDisposable()

    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        refreshManager = AppRepositoryRefreshManager()
    }

    override func tearDown() {
        super.tearDown()

        compositeDisposable.dispose()
    }

    func test_getRefresh_givenRefreshInProgressAndNewDelegateAddedAfter_expectAllDelegatesGetAllCallbacks() {
        let firstDelegate = MockRepositoryRefreshManagerDelegate()
        let firstDelegateExpectDelegateRefreshBegin = expectation(description: "Expect first delegate refresh begin.")
        let firstDelegateExpectDelegateRefreshComplete = expectation(description: "Expect first delegate refresh success to call.")
        firstDelegate.invokedRefreshBeginThen = {
            firstDelegateExpectDelegateRefreshBegin.fulfill()
        }
        firstDelegate.invokedRefreshCompleteThen = {
            firstDelegateExpectDelegateRefreshComplete.fulfill()
        }

        let refreshTask = ReplaySubject<FetchResponse<String, Error>>.createUnbounded()
        _ = refreshManager.getRefresh(task: refreshTask.asSingle(), tag: defaultRequirements.tag, requester: firstDelegate)

        let secondDelegate = MockRepositoryRefreshManagerDelegate()
        let secondDelegateExpectDelegateRefreshBegin = expectation(description: "Expect second delegate refresh begin.")
        let secondDelegateExpectDelegateRefreshComplete = expectation(description: "Expect second delegate refresh success to call.")
        secondDelegate.invokedRefreshBeginThen = {
            secondDelegateExpectDelegateRefreshBegin.fulfill()
        }
        secondDelegate.invokedRefreshCompleteThen = {
            secondDelegateExpectDelegateRefreshComplete.fulfill()
        }

        _ = refreshManager.getRefresh(task: refreshTask.asSingle(), tag: defaultRequirements.tag, requester: secondDelegate)

        refreshTask.onNext(FetchResponse.success(""))
        refreshTask.onCompleted()

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    // Tests that the refresh() function that returns an Observer is thread safe in that only creates a new Observer and starts a new refresh task when another one is not running.
    func test_multipleCallsToGetRefreshTask_resultInSameObserver() {
        // If the refresh() function does share the same observer, only 1 of the refresh tasks passed in will be observed. Not both which means that each of the refresh fetch tasks passed in were started.
        let expectOnlyOneRefreshTaskToBeObserved = expectation(description: "Expect one of the refresh tasks to be observed")
        expectOnlyOneRefreshTaskToBeObserved.expectedFulfillmentCount = 1
        expectOnlyOneRefreshTaskToBeObserved.assertForOverFulfill = true

        let delegate = MockRepositoryRefreshManagerDelegate()

        let observer1RefreshTask: Single<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()
            .asSingle()
            .do(onSubscribe: {
                expectOnlyOneRefreshTaskToBeObserved.fulfill()
            })

        let observer1 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        let observer2 = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)

        let observer2RefreshTask: Single<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()
            .asSingle()
            .do(onSubscribe: {
                expectOnlyOneRefreshTaskToBeObserved.fulfill()
            })

        // We do not know which of the 2 async background threads will be executed first. That's why we only have 1 expectation above shared between both of the `observerXrefreshTask`s because either one could be subscribed to depending on the order below.
        DispatchQueue(label: "observer1").async {
            let observer1RefreshManagerRefresh = self.refreshManager.getRefresh(task: observer1RefreshTask, tag: self.defaultRequirements.tag, requester: delegate)

            self.compositeDisposable += observer1RefreshManagerRefresh
                .asObservable()
                .subscribe(observer1)
        }
        DispatchQueue(label: "observer2").async {
            let observer2RefreshManagerRefresh = self.refreshManager.getRefresh(task: observer2RefreshTask, tag: self.defaultRequirements.tag, requester: delegate)

            self.compositeDisposable += observer2RefreshManagerRefresh
                .asObservable()
                .subscribe(observer2)
        }

        waitForExpectations(timeout: TestConstants.AWAIT_DURATION, handler: nil)
    }

    func test_cancel_refreshTaskGetsCancelled() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let doNotExpectDelegateRefreshComplete = expectation(description: "Do not expect manager delegate refresh success to call.")
        doNotExpectDelegateRefreshComplete.isInverted = true

        let delegate = MockRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            doNotExpectDelegateRefreshComplete.fulfill()
        }

        let observerRefreshTask: ReplaySubject<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveRefreshResultSkippedEvent = expectation(description: "Expect observer to receive fetch response to be skipped.")
        let doNotExpectObserverToReceiveOtherRefreshResults = expectation(description: "Expect observer to *not* receive any refresh results except for being skipped.")
        doNotExpectObserverToReceiveOtherRefreshResults.isInverted = true
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after manager is cancelled.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += refreshManager.getRefresh(task: observerRefreshTask.asSingle(), tag: defaultRequirements.tag, requester: delegate)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { refreshResult in
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

        refreshManager.cancelRefresh(tag: defaultRequirements.tag, requester: delegate)
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

        let delegate = MockRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            doNotExpectDelegateRefreshComplete.fulfill()
        }

        let observerRefreshTask: ReplaySubject<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveRefreshResultSkippedEvent = expectation(description: "Expect observer to receive fetch response to be skipped.")
        let doNotExpectObserverToReceiveOtherRefreshResults = expectation(description: "Expect observer to *not* receive any refresh results except for being skipped.")
        doNotExpectObserverToReceiveOtherRefreshResults.isInverted = true
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after manager is cancelled.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += refreshManager.getRefresh(task: observerRefreshTask.asSingle(), tag: defaultRequirements.tag, requester: delegate)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)) // unique thread.
            .do(onSuccess: { refreshResult in
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

    func test_refresh_delegateCallsInCorrectOrder() {
        let expectDelegateRefreshBegin = expectation(description: "Expect manager delegate refresh begin.")
        let expectDelegateRefreshComplete = expectation(description: "Expect manager delegate refresh success to call.")

        let delegate = MockRepositoryRefreshManagerDelegate()
        delegate.invokedRefreshBeginThen = {
            expectDelegateRefreshBegin.fulfill()
        }
        delegate.invokedRefreshCompleteThen = {
            expectDelegateRefreshComplete.fulfill()
        }

        let observerRefreshTask: ReplaySubject<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += refreshManager.getRefresh(task: observerRefreshTask.asSingle(), tag: defaultRequirements.tag, requester: delegate)
            .asObservable()
            .subscribe(observer)

        observerRefreshTask.onNext(FetchResponse<String, Error>.success("cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectDelegateRefreshBegin,
                   expectDelegateRefreshComplete], timeout: TestConstants.AWAIT_DURATION, enforceOrder: true)
    }

    func test_refresh_observerCallsInCorrectOrder() {
        let observerRefreshTask: ReplaySubject<FetchResponse<String, Error>> = ReplaySubject.createUnbounded()
        let delegate = MockRepositoryRefreshManagerDelegate()

        let expectObserverToSubscribeToRefresh = expectation(description: "Expect observer to subscribe to refresh observer.")
        let expectObserverToReceiveResultSuccessful = expectation(description: "Expect observer to receive fetch response to be successful.")
        let expectObserverToComplete = expectation(description: "Expect observer to complete refresh after fetch call complete.")

        let observer = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += refreshManager.getRefresh(task: observerRefreshTask.asSingle(), tag: defaultRequirements.tag, requester: delegate)
            .asObservable()
            .do(onNext: { refreshResult in
                if refreshResult == .successful {
                    expectObserverToReceiveResultSuccessful.fulfill()
                }
            }, onSubscribe: {
                expectObserverToSubscribeToRefresh.fulfill()
            }, onDispose: {
                expectObserverToComplete.fulfill()
            })
            .subscribe(observer)

        observerRefreshTask.onNext(FetchResponse<String, Error>.success("cache"))
        observerRefreshTask.onCompleted()

        wait(for: [expectObserverToSubscribeToRefresh,
                   expectObserverToReceiveResultSuccessful,
                   expectObserverToComplete], timeout: TestConstants.AWAIT_DURATION, enforceOrder: true)
    }

    func test_refresh_failureGetsPassedOn() {
        let expectRefreshObserverToReceiveError = expectation(description: "Expect observer to receive error from fetch")
        let expectRefreshObserverToDispose = expectation(description: "Expct observer to dispose after error received.")

        let refreshTask: PublishSubject<FetchResponse<String, Error>> = PublishSubject()
        let delegate = MockRepositoryRefreshManagerDelegate()

        let fetchFail = Fail()

        let refreshObserver = TestScheduler(initialClock: 0).createObserver(RefreshResult.self)
        compositeDisposable += refreshManager.getRefresh(task: refreshTask.asSingle(), tag: defaultRequirements.tag, requester: delegate)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onError: { error in
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

    class Fail: Error {}
}
