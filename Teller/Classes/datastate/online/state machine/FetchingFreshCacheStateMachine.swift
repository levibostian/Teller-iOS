//
//  FetchingFreshCacheStateMachine.swift
//  Teller
//
//  Created by Levi Bostian on 11/28/18.
//

import Foundation

/**
 State machine for fetching fresh cache data.
 */
internal class FetchingFreshCacheStateMachine {

    let state: State
    let errorDuringFetch: Error?
    let lastTimeFetched: Date

    var isFetching: Bool {
        return self.state == FetchingFreshCacheStateMachine.State.isFetching
    }

    private init(state: State, errorDuringFetch: Error?, lastTimeFetched: Date) {
        self.state = state
        self.errorDuringFetch = errorDuringFetch
        self.lastTimeFetched = lastTimeFetched
    }

    class func notFetching(lastTimeFetched: Date) -> FetchingFreshCacheStateMachine {
        return FetchingFreshCacheStateMachine(state: FetchingFreshCacheStateMachine.State.notFetching, errorDuringFetch: nil, lastTimeFetched: lastTimeFetched)
    }

    func fetching() -> FetchingFreshCacheStateMachine {
        return FetchingFreshCacheStateMachine(state: FetchingFreshCacheStateMachine.State.isFetching, errorDuringFetch: nil, lastTimeFetched: lastTimeFetched)
    }

    func failedFetching(_ error: Error) -> FetchingFreshCacheStateMachine {
        return FetchingFreshCacheStateMachine(state: FetchingFreshCacheStateMachine.State.notFetching, errorDuringFetch: error, lastTimeFetched: lastTimeFetched)
    }

    func successfulFetch(timeFetched: Date) -> FetchingFreshCacheStateMachine {
        return FetchingFreshCacheStateMachine(state: FetchingFreshCacheStateMachine.State.notFetching, errorDuringFetch: nil, lastTimeFetched: timeFetched)
    }

    internal enum State: CustomStringConvertible {
        case notFetching
        case isFetching

        var description: String {
            switch self {
            case .notFetching: return "Not fetching fresh cache data."
            case .isFetching: return "Fetching fresh cache data."
            }
        }
    }

}

extension FetchingFreshCacheStateMachine: CustomStringConvertible {

    var description: String {
        return self.state.description
    }

}
