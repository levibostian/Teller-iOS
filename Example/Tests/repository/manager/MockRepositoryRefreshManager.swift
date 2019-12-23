import Foundation
import RxSwift
@testable import Teller

internal class MockRepositoryRefreshManagerDelegate: RepositoryRefreshManagerDelegate {
    var invokedRefreshBegin = false
    var invokedRefreshBeginCount = 0
    var invokedRefreshBeginThen: (() -> Void)?
    func refreshBegin(requirements: RepositoryRequirements) {
        invokedRefreshBegin = true
        invokedRefreshBeginCount += 1
        invokedRefreshBeginThen?()
    }

    var invokedRefreshComplete = false
    var invokedRefreshCompleteCount = 0
    var invokedRefreshCompleteThen: (() -> Void)?
    func refreshComplete<String, Error>(_ response: FetchResponse<String, Error>, requirements: RepositoryRequirements, onComplete: @escaping () -> Void) {
        invokedRefreshComplete = true
        invokedRefreshCompleteCount += 1
        invokedRefreshCompleteThen?()

        onComplete()
    }
}

internal class MockRepositoryRefreshManager: RepositoryRefreshManager {
    init() {
        // Set default delegate so that tests can complete, by default.
        // func refreshComplete<String>(_ response: FetchResponse<String>, requirements: RepositoryRequirements, onComplete: @escaping () -> Void), the onComplete() param needs to be called for the tests to complete.
        self.delegate = MockRepositoryRefreshManagerDelegate()
    }

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
    var invokedRefreshParameters: (task: Single<FetchResponse<String, Error>>, Void)?
    var invokedRefreshParametersList = [(task: Single<FetchResponse<String, Error>>, Void)]()
    var stubbedRefreshResult: Single<RefreshResult>!
    func refresh<Fetch: Any, ErrorType: Error>(task: Single<FetchResponse<Fetch, ErrorType>>, requirements: RepositoryRequirements) -> Single<RefreshResult> {
        invokedRefresh = true
        invokedRefreshCount += 1
        invokedRefreshParameters = (task, ()) as! (task: Single<FetchResponse<String, Error>>, Void)
        invokedRefreshParametersList.append((task as! Single<FetchResponse<String, Error>>, ()))
        return stubbedRefreshResult
    }

    var invokedCancelRefresh = false
    var invokedCancelRefreshCount = 0
    func cancelRefresh() {
        invokedCancelRefresh = true
        invokedCancelRefreshCount += 1
    }
}
