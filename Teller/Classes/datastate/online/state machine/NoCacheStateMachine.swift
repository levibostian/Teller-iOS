//
//  FirstFetchStateMachine.swift
//  Teller
//
//  Created by Levi Bostian on 11/28/18.
//

import Foundation

/**
 State machine for the phase of data's lifecycle when no cache exists.
 */
internal class NoCacheStateMachine {

    let state: State
    let errorDuringFetch: Error?

    var isFetching: Bool {
        return state == NoCacheStateMachine.State.isFetching
    }

    private init(state: State, errorDuringFetch: Error?) {
        self.state = state
        self.errorDuringFetch = errorDuringFetch
    }

    class func noCacheExists() -> NoCacheStateMachine {
        return NoCacheStateMachine(state: NoCacheStateMachine.State.noCacheExists, errorDuringFetch: nil)
    }

    func fetching() -> NoCacheStateMachine {
        return NoCacheStateMachine(state: NoCacheStateMachine.State.isFetching, errorDuringFetch: nil)
    }

    func failedFetching(error: Error) -> NoCacheStateMachine {
        return NoCacheStateMachine(state: NoCacheStateMachine.State.noCacheExists, errorDuringFetch: error)
    }

    internal enum State: CustomStringConvertible {
        case noCacheExists
        case isFetching

        var description: String {
            switch self {
            case .noCacheExists: return "Cache data does not exist. It is not fetching data."
            case .isFetching: return "Cache data does not exist, but it is being fetched for first time."
            }
        }
    }

}

extension NoCacheStateMachine: CustomStringConvertible {

    var description: String {
        return self.state.description
    }

}
