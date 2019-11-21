import Foundation
import RxSwift

/*
 Because `RepositoryRefreshManager` contains an associatedType and want to be able to provide mocks of it in other Teller files, we need to use type erasure.
 */

private class _AnyRepositoryRefreshManagerBase<FetchResponseData: Any>: RepositoryRefreshManager {
    init() {
        guard type(of: self) != _AnyRepositoryRefreshManagerBase.self else {
            fatalError()
        }
    }

    var delegate: RepositoryRefreshManagerDelegate? {
        get {
            fatalError()
        }
        set { // swiftlint:disable:this unused_setter_value
            fatalError()
        }
    }

    func refresh(task: Single<FetchResponse<FetchResponseData>>) -> Single<RefreshResult> {
        fatalError()
    }

    func cancelRefresh() {
        fatalError()
    }
}

private final class _AnyRepositoryRefreshManagerBox<Concrete: RepositoryRefreshManager>: _AnyRepositoryRefreshManagerBase<Concrete.FetchResponseDataType> {
    var concrete: Concrete

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override var delegate: RepositoryRefreshManagerDelegate? {
        get {
            return self.concrete.delegate
        }
        set {
            self.concrete.delegate = newValue
        }
    }

    override func refresh(task: Single<FetchResponse<Concrete.FetchResponseDataType>>) -> Single<RefreshResult> {
        return concrete.refresh(task: task)
    }

    override func cancelRefresh() {
        concrete.cancelRefresh()
    }
}

internal final class AnyRepositoryRefreshManager<FetchResponseData: Any>: RepositoryRefreshManager {
    private let box: _AnyRepositoryRefreshManagerBase<FetchResponseData>

    init<Concrete: RepositoryRefreshManager>(_ concrete: Concrete) where Concrete.FetchResponseDataType == FetchResponseData {
        self.box = _AnyRepositoryRefreshManagerBox(concrete)
    }

    var delegate: RepositoryRefreshManagerDelegate? {
        get {
            return box.delegate
        }
        set {
            box.delegate = newValue
        }
    }

    func refresh(task: Single<FetchResponse<FetchResponseData>>) -> Single<RefreshResult> {
        return box.refresh(task: task)
    }

    func cancelRefresh() {
        box.cancelRefresh()
    }
}
