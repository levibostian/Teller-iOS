import Foundation

extension DataState {
    /**
     Parse the `DataState` for you to more easily display the state of the cache in your UI.
     */
    public enum State {
        /**
         It is undetermined if there is a cache that exists or not. This is usually the case for when just setting requirements on a `Repository`.
         */
        case none
        /**
         A cache has not been successfully fetched before.

         fetching - is a cache being fetched right now
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case noCache(fetching: Bool, errorDuringFetch: Error?)
        /**
         A cache has been successfully fetched before.

         cache - if nil, it's an empty cache. Else, it stores the cache data for you to display.
         lastFetched - The Date that the cache was last successfully fetched.
         firstCache - if true, the first cache has been successfully fetched for this cache.
         fetching - is the existing cache being updated right now?
         successfulFetch - if a fetch just finished and it was successful
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case cache(cache: DataType?, lastFetched: Date, firstCache: Bool, fetching: Bool, successfulFetch: Bool, errorDuringFetch: Error?)
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
        case fetching(fetching: Bool, noCache: Bool, errorDuringFetch: Error?, successfulFetch: Bool)
    }

    public func state() -> State {
        if isNone {
            return State.none
        }

        if noCacheExists {
            return State.noCache(fetching: fetchingForFirstTime, errorDuringFetch: errorDuringFirstFetch)
        } else {
            return State.cache(cache: cacheData, lastFetched: lastTimeFetched!, firstCache: justCompletedSuccessfulFirstFetch, fetching: isFetchingFreshData, successfulFetch: justCompletedSuccessfullyFetchingFreshData, errorDuringFetch: errorDuringFetch)
        }
    }

    public func fetchingState() -> FetchingState {
        return FetchingState.fetching(fetching: isFetchingFreshData || fetchingForFirstTime, noCache: noCacheExists, errorDuringFetch: errorDuringFirstFetch ?? errorDuringFetch, successfulFetch: justCompletedSuccessfulFirstFetch || justCompletedSuccessfullyFetchingFreshData)
    }
}

extension DataState.State: Equatable where DataType: Equatable {
    public static func == (lhs: DataState<DataType>.State, rhs: DataState<DataType>.State) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (let .noCache(fetching1, errorDuringFetch1), .noCache(let fetching2, let errorDuringFetch2)):
            return fetching1 == fetching2 &&
                ErrorsUtil.areErrorsEqual(lhs: errorDuringFetch1, rhs: errorDuringFetch2)
        case (let .cache(cache1, lastFetched1, firstCache1, fetching1, successfulFetch1, errorDuringFetch1), .cache(let cache2, let lastFetched2, let firstCache2, let fetching2, let successfulFetch2, let errorDuringFetch2)):
            return cache1 == cache2 &&
                lastFetched1.timeIntervalSince1970 == lastFetched2.timeIntervalSince1970 &&
                firstCache1 == firstCache2 &&
                fetching1 == fetching2 &&
                successfulFetch1 == successfulFetch2 &&
                ErrorsUtil.areErrorsEqual(lhs: errorDuringFetch1, rhs: errorDuringFetch2)
        default:
            return false
        }
    }
}
