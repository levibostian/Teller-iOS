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
        case noCache(state: (isRefreshing: Bool, refreshError: Error?))
        /**
         A cache has been successfully fetched before.

         cache - if nil, it's an empty cache. Else, it stores the cache data for you to display.
         lastFetched - The Date that the cache was last successfully fetched.
         firstCache - if true, the first cache has been successfully fetched for this cache.
         fetching - is the existing cache being updated right now?
         successfulFetch - if a fetch just finished and it was successful
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case cache(state: (cache: CacheType?, cacheAge: Date, justFinishedFirstFetch: Bool, isRefreshing: Bool, justFinishedSuccessfulRefresh: Bool, refreshError: Error?))
    }

    /**
     Parse the `DataState` for you to more easily display the fetching state of the cache in your UI.
     */
    public enum FetchingState {
        /**
         There is a fetch currently happening or a fetch just completeted.

         fetching - indicates if a fetch is happening right now
         noCache - if true, a cache has not been successfully fetched before
         errorDuringFetch - a fetch just finished but there was an error.
         successfulFetch - if a fetch just finished and it was successful
         */
        case fetching(state: (isRefreshing: Bool, cacheExists: Bool, refreshError: Error?, justFinishedSuccessfulRefresh: Bool))
    }

    public func state() -> State {
        if isNone {
            fatalError("Should not happen. Observing of a cache state should ignore none states")
        }

        if !cacheExists {
            return State.noCache(state: (isRefreshing: isRefreshing, refreshError: refreshError))
        } else {
            return State.cache(state: (cache: cache, cacheAge: cacheAge!, justFinishedFirstFetch: justFinishedFirstFetch, isRefreshing: isRefreshing, justFinishedSuccessfulRefresh: justFinishedSuccessfulRefresh, refreshError: refreshError))
        }
    }

    public func fetchingState() -> FetchingState {
        return FetchingState.fetching(state: (isRefreshing: isRefreshing, cacheExists: cacheExists, refreshError: refreshError, justFinishedSuccessfulRefresh: justFinishedSuccessfulRefresh))
    }
}

extension CacheState.State: Equatable where CacheType: Equatable {
    public static func == (lhs: CacheState<CacheType>.State, rhs: CacheState<CacheType>.State) -> Bool {
        switch (lhs, rhs) {
        case (let .noCache(state1), .noCache(let state2)):
            return state1.isRefreshing == state2.isRefreshing &&
                ErrorsUtil.areErrorsEqual(lhs: state1.refreshError, rhs: state2.refreshError)
        case (let .cache(state1), .cache(let state2)):
            return state1.cache == state2.cache &&
                state1.cacheAge.timeIntervalSince1970 == state2.cacheAge.timeIntervalSince1970 &&
                state1.justFinishedFirstFetch == state2.justFinishedFirstFetch &&
                state1.isRefreshing == state2.isRefreshing &&
                state1.justFinishedSuccessfulRefresh == state2.justFinishedSuccessfulRefresh &&
                ErrorsUtil.areErrorsEqual(lhs: state1.refreshError, rhs: state2.refreshError)
        default:
            return false
        }
    }
}
