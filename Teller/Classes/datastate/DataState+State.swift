import Foundation

extension CacheState {
    /**
     Parse the `DataState` for you to more easily display the state of the cache in your UI.
     */
    public enum State {
        /**
         A cache has not been successfully fetched before.

         fetching - is a cache being fetched right now
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case noCache
        /**
         A cache has been successfully fetched before.

         cache - if nil, it's an empty cache. Else, it stores the cache data for you to display.
         lastFetched - The Date that the cache was last successfully fetched.
         firstCache - if true, the first cache has been successfully fetched for this cache.
         fetching - is the existing cache being updated right now?
         successfulFetch - if a fetch just finished and it was successful
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case cache(cache: CacheType?, cacheAge: Date)
    }

    public var state: State {
        if isNone {
            fatalError("Should not happen. Observing of a cache state should ignore none states")
        }

        if !cacheExists {
            return State.noCache
        } else {
            return State.cache(cache: cache, cacheAge: cacheAge!)
        }
    }
}

extension CacheState.State: Equatable where CacheType: Equatable {
    public static func == (lhs: CacheState<CacheType>.State, rhs: CacheState<CacheType>.State) -> Bool {
        switch (lhs, rhs) {
        case (let .noCache, .noCache):
            return true
        case (let .cache(state1), .cache(let state2)):
            return state1.cache == state2.cache &&
                state1.cacheAge.timeIntervalSince1970 == state2.cacheAge.timeIntervalSince1970
        default:
            return false
        }
    }
}
