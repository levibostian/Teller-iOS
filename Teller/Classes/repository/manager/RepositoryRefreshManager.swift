import Foundation
import RxSwift

/**
 It's the delegate's responsibility to check the tag to in function call and compare that with the delegate's current requirements to decide if it should respond to the delegate call.
 */
internal protocol RepositoryRefreshManagerDelegate: AnyObject {
    func refreshBegin(tag: RepositoryRequirements.Tag)
    // Meaning network call was completed. The `FetchResponse` could still have a failure inside.
    // If the refresh request gets cancelled or skipped for any reason, this does *not* get called.
    func refreshSuccessful<FetchResponseData: Any, ErrorType: Error>( /* sourcery: Generic = "FetchResponse<String, TellerError>" */ _ response: FetchResponse<FetchResponseData, ErrorType>, tag: RepositoryRequirements.Tag)
}

/**
 You need to pass in a delegate into each of the functions because we handle the request depending on the Repository instance.
 */
internal protocol RepositoryRefreshManager {
    func getRefresh<FetchResponseData: Any, ErrorType: Error>( /* sourcery: Generic = "Single<FetchResponse<String, TellerError>>" */ task: Single<FetchResponse<FetchResponseData, ErrorType>>, tag: RepositoryRequirements.Tag, requester: RepositoryRefreshManagerDelegate) -> Single<RefreshResult>
    func cancelRefresh(tag: RepositoryRequirements.Tag, requester: RepositoryRefreshManagerDelegate)
}

/**
 In charge of managing `Repository.refresh()`'s fetching.

 This class guarantees:
 1. Can cancel the current refresh network fetch call, from any thread, and you will not receive any callbacks or updates from the manager concerning the cancelled call. Cancel the refresh call by setting your manager instance to nil.
 2. Runs 1 and only 1 refresh fetch call at one time. Multiple calls to `refresh()` result in receiving 1 fetch being created and started and all future calls receive a reference to the call already being performed. Once the call errors or succeeds, the next `refresh` call will created and started.
 3. Order of events (refresh begin, refresh end, fetch respone, fetch error) will be delivered in the correct order. The events will be sent to the delegate from a background thread

 The main inspiration for this class was that multiple threads can call `Repository.refresh()` at anytime, especially because `Repository.refresh()` gets called internally inside of `Repository`. There should *not* be multiple fetch calls happening at 1 given time. Only 1 should be happening. That is where the need for a thread safe refresh manager was born. Only run 1 refresh call, per instance, of this manager in a thread-safe way.
 */
internal class AppRepositoryRefreshManager: RepositoryRefreshManager {
    static let shared = AppRepositoryRefreshManager()

    private let refreshItems: Atomic<[RepositoryRequirements.Tag: RefreshTaskItem]> = Atomic(value: [:])

    // internal for testing access
    internal init() {}

    deinit {
        cancelAll()
    }

    func getRefresh<FetchResponseData, ErrorType>(task: Single<FetchResponse<FetchResponseData, ErrorType>>, tag: RepositoryRequirements.Tag, requester: RepositoryRefreshManagerDelegate) -> Single<RefreshResult> where ErrorType: Error {
        // Check if a refresh is already running for the tag. If not, start a refresh for it.
        // Check if the requester is already registered for the refresh task. If not, add it as a requester.
        // Return an observable to observe the status of the refresh request.

        let refreshListener = refreshItems.setMap { (refreshItems) -> (newValue: [String: RefreshTaskItem], return: RefreshRequester) in
            var refreshItems = refreshItems // to make it mutable

            if let existingRefreshItem = refreshItems[tag] {
                // A refresh has begun. Let's see if the delegate is registered yet as a listener
                if !existingRefreshItem.containsRequester(requester) {
                    requester.refreshBegin(tag: tag)

                    refreshItems[tag] = existingRefreshItem.addRequester(requester)
                }
            } else {
                /**
                 There is currently not a refresh happening for this tag. Start a new refresh

                 Calling delegate here as _runRefresh does not call it for us since we have a lock to the delegates in this function.
                 */
                requester.refreshBegin(tag: tag)

                let newRefreshStatus = ReplaySubject<RefreshResult>.create(bufferSize: 1)
                refreshItems[tag] = RefreshTaskItem(taskDisposable: _runRefresh(task: task, tag: tag), refreshStatus: newRefreshStatus, requesters: [
                    RefreshRequester(requester: requester, refreshStatus: newRefreshStatus)
                ])
            }

            return (refreshItems, refreshItems[tag]!.getRequester(requester)!)
        }

        return refreshListener.refreshStatus.asSingle()
    }

    private func _runRefresh<FetchResponseData: Any, ErrorType: Error>(task: Single<FetchResponse<FetchResponseData, ErrorType>>, tag: RepositoryRequirements.Tag) -> Disposable {
        return task.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onSuccess: { [weak self] fetchResponse in
                guard let self = self else { return }

                _ = self.refreshItems.set { (refreshItems) -> [String: RefreshTaskItem] in
                    var refreshItems = refreshItems

                    self.updateDelegates(refreshItem: refreshItems[tag]) { delegate in
                        delegate.refreshSuccessful(fetchResponse, tag: tag)
                    }

                    switch fetchResponse {
                    case .success:
                        self.doneRefresh(refreshTaskItem: refreshItems[tag], result: RefreshResult.successful, failure: nil)
                    case .failure(let failure):
                        self.doneRefresh(refreshTaskItem: refreshItems[tag], result: RefreshResult.failedError(error: failure), failure: nil)
                    }

                    refreshItems.removeValue(forKey: tag)

                    return refreshItems
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }

                _ = self.refreshItems.set { (refreshItems) -> [String: RefreshTaskItem] in
                    var refreshItems = refreshItems

                    self.doneRefresh(refreshTaskItem: refreshItems[tag], result: nil, failure: error)

                    refreshItems.removeValue(forKey: tag)

                    return refreshItems
                }
            })
    }

    private func doneRefresh(refreshTaskItem: RefreshTaskItem?, result: RefreshResult?, failure: Error?) {
        if let failure = failure {
            refreshTaskItem?.errorComplete(failure)
        } else {
            refreshTaskItem?.successfulComplete(result!)
        }
    }

    /**
     Required that this is called within a refreshItems.sync call. We don't call it in here to prevent locks.
     */
    private func updateDelegates(refreshItem: RefreshTaskItem?, update: (RepositoryRefreshManagerDelegate) -> Void) {
        refreshItem?.requesters.forEach { requester in
            if let delegate = requester.requester {
                update(delegate)
            }
        }
    }

    /**
     * Cancels the refresh request for only 1 requester. Leaves others alone.
     *
     *Useful for when [Repository.requirements] is changed and the previous [Repository.fetchFreshCache] call (if there was one) should be cancelled as a new [Repository.fetchFreshCache] could be triggered.
     *
     * If the [repository] is not found in the list of added owners for [tag], the request will be ignored.
     *
     * If there are 0 [RepositoryRefreshManager.Listener]s after removing the [repository] for the given [tag], the actual fetch call will be cancelled for performance gain. If there is 1+ other [RepositoryRefreshManager.Listener]s that are still using the fetch request with the given [tag], the actual [Repository.fetchFreshCache] will continue but the given [repository] will not get a notification on updates.
     *
     * The [Single] returned from [refresh] will receive a [Repository.RefreshResult.SkippedReason.CANCELLED] event on cancel.
     */
    func cancelRefresh(tag: RepositoryRequirements.Tag, requester: RepositoryRefreshManagerDelegate) {
        _ = refreshItems.set { (refreshItems) -> [String: RefreshTaskItem] in
            var refreshItems = refreshItems

            if let refreshItem = refreshItems[tag] {
                var refreshRequestersToCancel: [RefreshRequester] = []

                if let refreshRequester = refreshItem.getRequester(requester) {
                    refreshRequestersToCancel.append(refreshRequester)
                }
                /**
                 The Repository instance may be nil, but the observer who is observing Repository.refresh() may still be observing the refresh call. We need to cancel those requests as well.
                 */
                refreshRequestersToCancel.append(contentsOf: refreshItem.getNilRequesters())

                refreshRequestersToCancel.forEach { refreshRequester in
                    let status = refreshRequester.refreshStatus
                    status.onNext(RefreshResult.skipped(reason: .cancelled))
                    status.onCompleted()

                    let updatedRefreshItem = refreshItem.removeRequester(requester)
                    refreshItems[tag] = updatedRefreshItem

                    if updatedRefreshItem.requesters.isEmpty {
                        refreshItem.cancel()

                        refreshItems.removeValue(forKey: tag)
                    }
                }
            }

            return refreshItems
        }
    }

    func cancelAll() {
        _ = refreshItems.set { (refreshItems) -> [String: RefreshTaskItem] in
            refreshItems.forEach { arg0 in
                let (_, value) = arg0

                value.successfulComplete(RefreshResult.skipped(reason: .cancelled))
                value.taskDisposable.dispose()
            }

            return [:]
        }
    }

    /**
     * Represents a refresh network call task. Keep a status of the refresh task and the ability to cancel it by disposing the Disposable.
     *
     * Why a ReplaySubject? Well, when you call `refresh()` and receive an instance of this `subject.asSingle()`, that Single instance may not be subscribed to right away. Especially in a multi threaded environment, there may be a delay for the subscribe to complete. Therefore, it is possible for the observer of `subject.asSingle()` to subscribe between (or after) the `subject.onNext()` call and the `subject.complete` call. As stated already, if you only receive the `complete` call, you will receive an RxError for sequence not containing any elements.
     To prevent this scenario, we use a ReplaySubject. That way when an observer subscribes to the Single, they will be guaranteed to not receive the RxError as it will or will not receive a `Single.success` call.
     */
    private struct RefreshTaskItem {
        let taskDisposable: Disposable
        /**
         Exists for convenience. The refresh status for all of the requesters although each requester may have their own separate refresh status via `RefreshRequester.refreshStatus`
         */
        let refreshStatus: ReplaySubject<RefreshResult>
        let requesters: [RefreshRequester]

        /**
         You should not use this object after calling complete. That's why there is no return type.
         */
        func successfulComplete(_ result: RefreshResult) {
            requesters.forEach {
                $0.refreshStatus.onNext(result)
                $0.refreshStatus.onCompleted()
            }
        }

        /**
         You should not use this object after calling complete. That's why there is no return type.
         */
        func errorComplete(_ error: Error) {
            requesters.forEach {
                $0.refreshStatus.onError(error)
                $0.refreshStatus.onCompleted()
            }
        }

        /**
         You should not use this object after calling cancel. That's why there is no return value.
         */
        func cancel() {
            taskDisposable.dispose()
        }

        func containsRequester(_ requester: AnyObject) -> Bool {
            return getRequester(requester) != nil
        }

        func getRequester(_ requester: AnyObject) -> RefreshRequester? {
            return requesters.first { (existingRequester) -> Bool in
                existingRequester.requester === requester
            }
        }

        func getNilRequesters() -> [RefreshRequester] {
            return requesters.filter { $0.requester == nil }
        }

        func addRequester(_ requester: RepositoryRefreshManagerDelegate) -> RefreshTaskItem {
            guard !containsRequester(requester) else {
                return self
            }

            var requesters = self.requesters
            requesters.append(RefreshRequester(requester: requester, refreshStatus: refreshStatus))

            return RefreshTaskItem(taskDisposable: taskDisposable, refreshStatus: refreshStatus, requesters: requesters)
        }

        func removeRequester(_ requester: AnyObject) -> RefreshTaskItem {
            guard containsRequester(requester) else {
                return self
            }

            var requesters = self.requesters
            requesters.removeAll { (existingRequester) -> Bool in
                existingRequester.requester === requester
            }

            return RefreshTaskItem(taskDisposable: taskDisposable, refreshStatus: refreshStatus, requesters: requesters)
        }
    }

    private struct RefreshRequester {
        weak var requester: RepositoryRefreshManagerDelegate?
        /**
         Each requester needs it's own separate refresh status because if it cancels early, the requester's status is set to cancelled but all other requesters of the same refresh tag will not recieve the cancelled response.
         */
        let refreshStatus: ReplaySubject<RefreshResult>
    }
}
