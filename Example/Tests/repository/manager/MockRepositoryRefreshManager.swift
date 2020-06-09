import Foundation
import RxSwift
@testable import Teller

internal class MockRepositoryRefreshManagerDelegate: RepositoryRefreshManagerDelegate {
    var invokedRefreshBegin = false
    var invokedRefreshBeginCount = 0
    var invokedRefreshBeginThen: (() -> Void)?
    func refreshBegin(tag: String) {
        invokedRefreshBegin = true
        invokedRefreshBeginCount += 1
        invokedRefreshBeginThen?()
    }

    var invokedRefreshComplete = false
    var invokedRefreshCompleteCount = 0
    var invokedRefreshCompleteThen: (() -> Void)?
    func refreshSuccessful<FetchResponseData, ErrorType>(_ response: FetchResponse<FetchResponseData, ErrorType>, tag: String) where ErrorType: Error {
        invokedRefreshComplete = true
        invokedRefreshCompleteCount += 1
        invokedRefreshCompleteThen?()
    }
}

internal class MockRepositoryRefreshManager: RepositoryRefreshManager {
    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: RepositoryRefreshManagerDelegate?
    var invokedDelegateList = [RepositoryRefreshManagerDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: RepositoryRefreshManagerDelegate!
    var delegate: RepositoryRefreshManagerDelegate? {
        set {
            invokedDelegateSetter = true
            invokedDelegateSetterCount += 1
            invokedDelegate = newValue
            invokedDelegateList.append(newValue)
        }
        get {
            invokedDelegateGetter = true
            invokedDelegateGetterCount += 1
            return stubbedDelegate
        }
    }

    var invokedAddDelegate = false
    var invokedAddDelegateCount = 0
    func addDelegate(_ delegate: RepositoryRefreshManagerDelegate) {
        invokedAddDelegate = true
        invokedAddDelegateCount += 1
    }

    var invokedRemoveDelegate = false
    var invokedRemoveDelegateCount = 0
    func removeDelegate(_ delegate: RepositoryRefreshManagerDelegate) {
        invokedRemoveDelegate = true
        invokedRemoveDelegateCount += 1
    }

    var invokedRefresh = false
    var invokedRefreshCount = 0
    var invokedRefreshParameters: (task: Single<FetchResponse<String, Error>>, Void)?
    var invokedRefreshParametersList = [(task: Single<FetchResponse<String, Error>>, Void)]()
    var stubbedRefreshResult: Single<RefreshResult>!
    func getRefresh<FetchResponseData, ErrorType>(task: Single<FetchResponse<FetchResponseData, ErrorType>>, tag: String, requester: RepositoryRefreshManagerDelegate) -> Single<RefreshResult> where ErrorType: Error {
        invokedRefresh = true
        invokedRefreshCount += 1
        invokedRefreshParameters = (task, ()) as! (task: Single<FetchResponse<String, Error>>, Void)
        invokedRefreshParametersList.append((task as! Single<FetchResponse<String, Error>>, ()))
        return stubbedRefreshResult
    }

    var invokedCancelRefresh = false
    var invokedCancelRefreshCount = 0
    func cancelRefresh(tag: String, requester: RepositoryRefreshManagerDelegate) {
        invokedCancelRefresh = true
        invokedCancelRefreshCount += 1
    }
}
