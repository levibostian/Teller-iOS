import Foundation

/**
 Set the state of a Teller `Repository` for integration testing.
 Using one of the functions in this class will allow you to quickly and easily set the cache state of a `Repository` before you run the code under test.
 */
public class RepositoryTesting {
    private let syncStateManager: RepositorySyncStateManager

    private init() {
        self.syncStateManager = TellerRepositorySyncStateManager()
    }

    /**
     Initialize the state of a Teller `Repository`.

     This function runs `Repository.saveCache()` on the current thread you call this function on. If you need to run the `saveCache()` function on a background thread, use `initStateAsync()` instead.
     */
    public static func initState<DataSource: RepositoryDataSource>(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) -> SetValues {
        return RepositoryTesting().initState(repository: repository, requirements: requirements, more: more)
    }

    /**
     Initialize the state of a Teller `Repository`.

     This function runs `Repository.saveCache()` on a background thread. If you do not care what thread run the `saveCache()` function runs on, use `initState()` instead.
     */
    public static func initStateAsync<DataSource: RepositoryDataSource>(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, onComplete: @escaping (SetValues) -> Void, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) {
        return RepositoryTesting().initStateAsync(repository: repository, requirements: requirements, onComplete: onComplete, more: more)
    }

    private func initStateAsync<DataSource: RepositoryDataSource>(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, onComplete: @escaping (SetValues) -> Void, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) {
        var cacheExistsDsl = StateOfOnlineRepositoryDsl<DataSource.FetchResult>()
        if let more = more {
            more(&cacheExistsDsl)
        }

        var setValues = SetValues(lastFetched: nil)

        let proposedState = cacheExistsDsl.props
        if proposedState.cacheExists {
            let lastFetched = initStateLastFetched(repository: repository, requirements: requirements, cacheExistsDsl: cacheExistsDsl)

            setValues = SetValues(lastFetched: lastFetched)

            if let proposedCache = proposedState.cache {
                DispatchQueue.global(qos: .background).async {
                    try! repository.dataSource.saveCache(proposedCache, requirements: requirements)

                    onComplete(setValues)
                }
            } else {
                onComplete(setValues)
            }
        } else {
            // No cache exists. Ignore request, assume that dev cleared.
            onComplete(setValues)
        }
    }

    private func initStateLastFetched<DataSource: RepositoryDataSource>(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, cacheExistsDsl: StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Date {
        var lastFetched = cacheExistsDsl.cacheExistsDsl?.props.lastFetched ?? Date()
        if let proposedCacheState = cacheExistsDsl.cacheExistsDsl?.props {
            if proposedCacheState.cacheTooOld {
                let maxAgeOfCachePlusHour = Calendar.current.date(byAdding: .hour, value: 1, to: repository.dataSource.maxAgeOfCache.toDate())!

                lastFetched = maxAgeOfCachePlusHour
            }
        }

        syncStateManager.updateAgeOfData(tag: requirements.tag, age: lastFetched)

        return lastFetched
    }

    private func initState<DataSource: RepositoryDataSource>(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) -> SetValues {
        var cacheExistsDsl = StateOfOnlineRepositoryDsl<DataSource.FetchResult>()
        if let more = more {
            more(&cacheExistsDsl)
        }

        var setValues = SetValues(lastFetched: nil)

        let proposedState = cacheExistsDsl.props
        if proposedState.cacheExists {
            if let proposedCache = proposedState.cache {
                try! repository.dataSource.saveCache(proposedCache, requirements: requirements)
            }

            let lastFetched = initStateLastFetched(repository: repository, requirements: requirements, cacheExistsDsl: cacheExistsDsl)

            setValues = SetValues(lastFetched: lastFetched)
        } else {
            // No cache exists. Ignore request, assume that dev cleared.
        }

        return setValues
    }

    /**
     * The values set in one of the `RepositoryTesting` init functions.
     */
    public struct SetValues: Equatable {
        let lastFetched: Date?
    }
}

/**
 Swift DSL for setting the state of a Teller `Repository`.

 @see RepositoryTesting
 */
public class StateOfOnlineRepositoryDsl<DataType: Any> {
    internal var props = Props.getDefault()
    internal var cacheExistsDsl: CaheExistsDsl<DataType>?

    internal init() {}

    /**
     The Teller `Repository` has no cache. No cache has been successfully fetched before.
     */
    public func noCache() {
        props = Props(cacheExists: false,
                      cache: nil)
    }

    /**
     The Teller `Repository` has an empty cache. A cache has been successfully fetched before, but it's empty.
     */
    public func cacheEmpty(more: ((inout CaheExistsDsl<DataType>) -> Void)? = nil) {
        props = Props(cacheExists: true,
                      cache: nil)

        if let more = more {
            cacheExistsDsl = CaheExistsDsl<DataType>()
            more(&cacheExistsDsl!)
        } else {
            cacheExistsDsl = nil
        }
    }

    /**
     The Teller `Repository` has a cache. A cache has been successfully fetched before and is not empty.
     */
    public func cache(_ cache: DataType, more: ((inout CaheExistsDsl<DataType>) -> Void)? = nil) {
        props = Props(cacheExists: true,
                      cache: cache)

        if let more = more {
            cacheExistsDsl = CaheExistsDsl<DataType>()
            more(&cacheExistsDsl!)
        } else {
            cacheExistsDsl = nil
        }
    }

    /**
     Swift DSL for setting the cache state of a Teller `Repository` when a cache does exist.

     @see StateOfOnlineRepositoryDsl
     */
    public class CaheExistsDsl<DataType: Any> {
        var props = Props.getDefault()

        /**
         Set the time that the cache was last fetched successfully.
         */
        public func lastFetched(_ lastFetched: Date) {
            props = Props(lastFetched: lastFetched, cacheTooOld: false, cacheNotTooOld: false)
        }

        /**
         State that the time the cache was last fetched successfully is too old and should be updated.
         */
        public func cacheTooOld() {
            props = Props(lastFetched: nil, cacheTooOld: true, cacheNotTooOld: false)
        }

        /**
         State that the time the cache was last fetched successfully is not too old and should not be updated.
         */
        public func cacheNotTooOld() {
            props = Props.getDefault()
        }

        /**
         * Make default where cache not too old (make cache last fetched now) to give [OnlineRepository] the minimum amount of interactions. There must be *some* last fetched time because cache does exist!
         */
        struct Props { // swiftlint:disable:this nesting
            let lastFetched: Date?
            let cacheTooOld: Bool
            let cacheNotTooOld: Bool

            static func getDefault() -> Props {
                return Props(lastFetched: nil, cacheTooOld: false, cacheNotTooOld: true)
            }
        }
    }

    internal struct Props {
        let cacheExists: Bool
        let cache: DataType?

        static func getDefault() -> Props {
            return Props(cacheExists: false,
                         cache: nil)
        }
    }
}
