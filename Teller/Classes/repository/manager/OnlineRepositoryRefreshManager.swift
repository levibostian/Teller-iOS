//
//  OnlineRepositoryRefreshManager.swift
//  Teller
//
//  Created by Levi Bostian on 12/4/18.
//

import Foundation
import RxSwift

internal protocol OnlineRepositoryRefreshManagerDelegate: AnyObject {
    func refreshBegin()
    // Meaning network call was completed. The `FetchResponse` could still have a failure inside.
    // If the refresh request gets cancelled or skipped for any reason, this does *not* get called.
    func refreshComplete<FetchResponseData: Any>(_ response: FetchResponse<FetchResponseData>)
}

internal protocol OnlineRepositoryRefreshManager {
    associatedtype FetchResponseDataType

    var delegate: OnlineRepositoryRefreshManagerDelegate? { get set }
    func refresh(task: Single<FetchResponse<FetchResponseDataType>>) -> Single<RefreshResult>
    func cancelRefresh()
}

/**
 In charge of managing `OnlineRepository.refresh()`'s fetching.

 This class guarantees:
 1. Can cancel the current refresh network fetch call, from any thread, and you will not receive any callbacks or updates from the manager concerning the cancelled call. Cancel the refresh call by setting your manager instance to nil.
 2. Runs 1 and only 1 refresh fetch call at one time. Multiple calls to `refresh()` result in receiving 1 fetch being created and started and all future calls receive a reference to the call already being performed. Once the call errors or succeeds, the next `refresh` call will created and started.
 3. Order of events (refresh begin, refresh end, fetch respone, fetch error) will be delivered in the correct order. The events will be sent to the delegate from a background thread

 The main inspiration for this class was that multiple threads can call `OnlineRepository.refresh()` at anytime, especially because `OnlineRepository.refresh()` gets called internally inside of `OnlineRepository`. There should *not* be multiple fetch calls happening at 1 given time. Only 1 should be happening. That is where the need for a thread safe refresh manager was born. Only run 1 refresh call, per instance, of this manager in a thread-safe way.
 */
internal class AppOnlineRepositoryRefreshManager<FetchResponseData: Any>: OnlineRepositoryRefreshManager {

    typealias FetchResponseDataType = FetchResponseData

    weak var delegate: OnlineRepositoryRefreshManagerDelegate? = nil

    /*
     Why use a Subject? In this manager, we are using `Single`s for observing the `refresh()` result. We are using a subject to update the `refresh()` status because we can call `onNext()` directly on it in the manager instance.
     How does the Subject need to work? In order to use a Subject as a Single, you need to call `onNext()` followed by `onCompleted()` on the subject in order for the Single.success to be called and delivered to the observers. If you only call complete(), you will receive an RxError "Event error(Sequence doesn't contain any elements.)". If you only call onNext(), nothing will happen.
     Why a ReplaySubject? Well, when you call `refresh()` and receive an instance of this `subject.asSingle()`, that Single instance may not be subscribed to right away. Especially in a multi threaded environment, there may be a delay for the subscribe to complete. Therefore, it is possible for the observer of `subject.asSingle()` to subscribe between (or after) the `subject.onNext()` call and the `subject.complete` call. As stated already, if you only receive the `complete` call, you will receive an RxError for sequence not containing any elements.
     To prevent this scenario, we use a ReplaySubject. That way when an observer subscribes to the Single, they will be guaranteed to not receive the RxError as it will or will not receive a `Single.success` call.
    */
    fileprivate var refreshSubject: ReplaySubject<RefreshResult>? = nil

    fileprivate var refreshTaskDisposeBag: DisposeBag = DisposeBag()

    // Queue for reading and writing `refreshSubject` in a thread-safe way. Serial queue to make sure that only 1 refresh can be started at one time.
    private let refreshSubjectQueue = DispatchQueue(label: "\(TellerConstants.namespace)_AppOnlineRepositoryRefreshManager_refreshSubjectQueue")
    // Serial queue to run refresh so only 1 refresh call is ever run at 1 time.
    private let runRefreshScheduler = SerialDispatchQueueScheduler(qos: DispatchQoS.userInitiated, internalSerialQueueName: "\(TellerConstants.namespace)_AppOnlineRepositoryRefreshManager_runRefreshScheduler", leeway: DispatchTimeInterval.never)

    init() {
    }

    deinit {
        cancelRefresh()
    }

    func refresh(task: Single<FetchResponse<FetchResponseData>>) -> Single<RefreshResult> {
        var refreshSubCopy: ReplaySubject<RefreshResult>!

        refreshSubjectQueue.sync {
            if let refreshSubject = self.refreshSubject {
                refreshSubCopy = refreshSubject
            } else {
                let newSubject = ReplaySubject<RefreshResult>.createUnbounded()
                self.refreshSubject = newSubject
                refreshSubCopy = newSubject

                self._runRefresh(task: task)
            }
        }

        return refreshSubCopy.asSingle()
    }

    private func _runRefresh(task: Single<FetchResponse<FetchResponseData>>) {
        task
            .do(onSubscribe: { [weak self] in // Do not use `onSubscribed` as it triggers the update *after* the fetch is complete in tests instead of before.
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.refreshBegin()
                }
            })
            .subscribeOn(runRefreshScheduler)
            .subscribe(onSuccess: { [weak self] (fetchResponse) in
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.refreshComplete(fetchResponse)

                    if let fetchError = fetchResponse.failure {
                        self?.doneRefresh(result: RefreshResult.fail(fetchError), failure: nil)
                    } else {
                        self?.doneRefresh(result: RefreshResult.success(), failure: nil)
                    }
                }
            }) { [weak self] (error) in
                self?.doneRefresh(result: nil, failure: error)
        }.disposed(by: refreshTaskDisposeBag)
    }

    private func doneRefresh(result: RefreshResult?, failure: Error?) {
        refreshSubjectQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if let failure = failure {
                self.refreshSubject?.onError(failure)
            } else {
                self.refreshSubject?.onNext(result!)
            }

            self.refreshSubject?.onCompleted()
            self.refreshSubject = nil
        }
    }

    // Cancel refresh. Start up another one by calling `refresh()`.
    func cancelRefresh() {
        refreshSubjectQueue.sync {
            self.refreshTaskDisposeBag = DisposeBag()

            self.refreshSubject?.onNext(RefreshResult.skipped(RefreshResult.SkippedReason.cancelled))
            self.refreshSubject?.onCompleted()
            self.refreshSubject = nil
        }
    }

}