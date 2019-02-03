//
//  OnlineRepositoryRefreshManager+TypeErasure.swift
//  Teller
//
//  Created by Levi Bostian on 12/7/18.
//

import Foundation
import RxSwift

/*
 Because `OnlineRepositoryRefreshManager` contains an associatedType and want to be able to provide mocks of it in other Teller files, we need to use type erasure.
 */

private class _AnyOnlineRepositoryRefreshManagerBase<FetchResponseData: Any>: OnlineRepositoryRefreshManager {

    init() {
        guard type(of: self) != _AnyOnlineRepositoryRefreshManagerBase.self else {
            fatalError()
        }
    }

    var delegate: OnlineRepositoryRefreshManagerDelegate? {
        get {
            fatalError()
        }
        set {
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

private final class _AnyOnlineRepositoryRefreshManagerBox<Concrete: OnlineRepositoryRefreshManager>: _AnyOnlineRepositoryRefreshManagerBase<Concrete.FetchResponseDataType> {

    var concrete: Concrete

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override var delegate: OnlineRepositoryRefreshManagerDelegate? {
        get {
            return self.concrete.delegate
        }
        set {
            self.concrete.delegate = newValue
        }
    }

    override func refresh(task: Single<FetchResponse<Concrete.FetchResponseDataType>>) -> Single<RefreshResult> {
        return self.concrete.refresh(task: task)
    }

    override func cancelRefresh() {
        self.concrete.cancelRefresh()
    }

}

internal final class AnyOnlineRepositoryRefreshManager<FetchResponseData: Any>: OnlineRepositoryRefreshManager {

    private let box: _AnyOnlineRepositoryRefreshManagerBase<FetchResponseData>

    init<Concrete: OnlineRepositoryRefreshManager>(_ concrete: Concrete) where Concrete.FetchResponseDataType == FetchResponseData {
        box = _AnyOnlineRepositoryRefreshManagerBox(concrete)
    }

    var delegate: OnlineRepositoryRefreshManagerDelegate? {
        get {
            return self.box.delegate
        }
        set {
            self.box.delegate = newValue
        }
    }

    func refresh(task: Single<FetchResponse<FetchResponseData>>) -> Single<RefreshResult> {
        return self.box.refresh(task: task)
    }

    func cancelRefresh() {
        self.box.cancelRefresh()
    }

}
