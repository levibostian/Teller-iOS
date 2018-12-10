//
//  MockOnlineRepositoryRefreshManager.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 12/7/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
@testable import Teller

internal class MockOnlineRepositoryRefreshManagerDelegate: OnlineRepositoryRefreshManagerDelegate {
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

internal class MockOnlineRepositoryRefreshManager<FetchResponseDataType: Any>: OnlineRepositoryRefreshManager {

    var invokedDelegateSetter = false
    var invokedDelegateSetterCount = 0
    var invokedDelegate: OnlineRepositoryRefreshManagerDelegate?
    var invokedDelegateList = [OnlineRepositoryRefreshManagerDelegate?]()
    var invokedDelegateGetter = false
    var invokedDelegateGetterCount = 0
    var stubbedDelegate: OnlineRepositoryRefreshManagerDelegate!
    var delegate: OnlineRepositoryRefreshManagerDelegate? {
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
