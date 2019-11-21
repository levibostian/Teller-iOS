import Foundation
import RxSwift
@testable import Teller

internal class MockRepositoryRefreshManagerDelegate: RepositoryRefreshManagerDelegate {
    var invokedRefreshBegin = false
    var invokedRefreshBeginCount = 0
    var invokedRefreshBeginThen: (() -> Void)?
    func refreshBegin() {
        invokedRefreshBegin = true
        invokedRefreshBeginCount += 1
        invokedRefreshBeginThen?()
    }

    var invokedRefreshComplete = false
    var invokedRefreshCompleteCount = 0
    var invokedRefreshCompleteThen: (() -> Void)?
    func refreshComplete<String>(_ response: FetchResponse<String>) {
        invokedRefreshComplete = true
        invokedRefreshCompleteCount += 1
        invokedRefreshCompleteThen?()
    }
}

internal class MockRepositoryRefreshManager<FetchResponseDataType: Any>: RepositoryRefreshManager {
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

    var invokedRefresh = false
    var invokedRefreshCount = 0
    var invokedRefreshParameters: (task: Single<FetchResponse<FetchResponseDataType>>, Void)?
    var invokedRefreshParametersList = [(task: Single<FetchResponse<FetchResponseDataType>>, Void)]()
    var stubbedRefreshResult: Single<RefreshResult>!
    func refresh(task: Single<FetchResponse<FetchResponseDataType>>) -> Single<RefreshResult> {
        invokedRefresh = true
        invokedRefreshCount += 1
        invokedRefreshParameters = (task, ())
        invokedRefreshParametersList.append((task, ()))
        return stubbedRefreshResult
    }

    var invokedCancelRefresh = false
    var invokedCancelRefreshCount = 0
    func cancelRefresh() {
        invokedCancelRefresh = true
        invokedCancelRefreshCount += 1
    }
}
