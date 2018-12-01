//
//  CacheStateMachine.swift
//  Teller
//
//  Created by Levi Bostian on 11/28/18.
//

import Foundation

/**
 State machine for the phase of data's lifecycle when a cache exists.
 */
internal class CacheStateMachine<Data: Any> {

    let state: State
    let cache: Data?

    private init(state: State, cache: Data?) {
        self.state = state
        self.cache = cache
    }

    // MARK - constructors
    class func cacheEmpty() -> CacheStateMachine {
        return CacheStateMachine(state: CacheStateMachine<Data>.State.cacheEmpty, cache: nil)
    }

    class func cacheExists(_ cache: Data) -> CacheStateMachine {
        return CacheStateMachine(state: CacheStateMachine<Data>.State.cacheNotEmpty, cache: cache)
    }

    internal enum State: CustomStringConvertible {
        case cacheEmpty
        case cacheNotEmpty

        var description: String {
            switch self {
            case .cacheEmpty: return "Cache data exists and is empty."
            case .cacheNotEmpty: return "Cache data exists and is not empty."
            }
        }
    }

}

extension CacheStateMachine: CustomStringConvertible {

    var description: String {
        return self.state.description
    }

}
