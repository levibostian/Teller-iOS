import Foundation

public typealias PagedCacheState<PagedCacheType: Any> = CacheState<PagedCache<PagedCacheType>>

public extension CacheState {
    func convert<OldCache: Any, NewCache: Any>(_ convert: (OldCache?) -> NewCache?) -> CacheState<PagedCache<NewCache>> where CacheType == PagedCache<OldCache> {
        var newPagedCache: PagedCache<NewCache>?
        if let existingCache = cache {
            if let newCache = convert(existingCache.cache) {
                newPagedCache = PagedCache(areMorePages: existingCache.areMorePages, cache: newCache)
            }
        }

        /// Notice that because this function is not used internally in the library, we provide `nil` as the state machine because that does not matter.
        return CacheState<PagedCache<NewCache>>(cacheExists: cacheExists,
                                                cache: newPagedCache,
                                                cacheAge: cacheAge,
                                                isRefreshing: isRefreshing,
                                                requirements: requirements,
                                                stateMachine: nil,
                                                justFinishedSuccessfulRefresh: justFinishedSuccessfulRefresh,
                                                justFinishedFirstFetch: justFinishedFirstFetch,
                                                refreshError: refreshError)
    }
}
