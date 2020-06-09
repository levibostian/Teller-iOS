import Foundation

public class CacheStateTesting {
    private init() {}

    public static func noCache<DataType: Any>(requirements: RepositoryRequirements, more: ((inout NoCacheExistsDsl) -> Void)? = nil) -> CacheState<DataType> {
        var noCacheExists = NoCacheExistsDsl()

        if let more = more {
            more(&noCacheExists)
        }

        /**
         * We are using the [CacheStateStateMachine] here to (1) prevent duplicate constructor code that is a pain to maintain and (2) we are starting with the assumption that no cache exists and editing the state from there if the DSL asks for it.
         */
        var stateMachine = DataStateStateMachine<DataType>.noCacheExists(requirements: requirements)

        if noCacheExists.props.fetchingFirstTime {
            stateMachine = try! stateMachine.change().firstFetch()
        }

        if let errorDuringFirstFetch = noCacheExists.props.errorDuringFirstFetch {
            stateMachine = try! stateMachine.change()
                .firstFetch().change()
                .errorFirstFetch(error: errorDuringFirstFetch)
        }

        if noCacheExists.props.successfulFirstFetch {
            stateMachine = try! stateMachine.change()
                .firstFetch().change()
                .successfulFirstFetch(timeFetched: noCacheExists.props.timeFetched!)
        }

        return stateMachine
    }

    public static func cache<DataType: Any>(requirements: RepositoryRequirements, lastTimeFetched: Date, more: ((inout CacheExistsDsl<DataType>) -> Void)? = nil) -> CacheState<DataType> {
        var cacheExists = CacheExistsDsl<DataType>()

        if let more = more {
            more(&cacheExists)
        }

        var stateMachine = DataStateStateMachine<DataType>.cacheExists(requirements: requirements, lastTimeFetched: lastTimeFetched)

        if let cache = cacheExists.props.cache {
            stateMachine = try! stateMachine.change()
                .cachedData(cache)
        } else {
            stateMachine = try! stateMachine.change()
                .cacheIsEmpty()
        }

        if cacheExists.props.fetching {
            stateMachine = try! stateMachine.change().fetchingFreshCache()
        }

        if let fetchError = cacheExists.props.errorDuringFetch {
            stateMachine = try! stateMachine.change()
                .fetchingFreshCache().change()
                .failFetchingFreshCache(fetchError)
        }

        if cacheExists.props.successfulFetch {
            stateMachine = try! stateMachine.change()
                .fetchingFreshCache().change()
                .successfulFetchingFreshCache(timeFetched: cacheExists.props.successfulFetchTime!)
        }

        return stateMachine
    }
}

public class NoCacheExistsDsl {
    internal var props = Props()

    internal init() {}

    public func fetchingFirstTime() {
        props = Props()
        props.fetchingFirstTime = true
    }

    public func failedFirstFetch(error: Error) {
        props = Props()
        props.errorDuringFirstFetch = error
    }

    public func successfulFirstFetch(timeFetched: Date) {
        props = Props()
        props.successfulFirstFetch = true
        props.timeFetched = timeFetched
    }

    internal struct Props {
        var fetchingFirstTime: Bool = false
        var errorDuringFirstFetch: Error?
        var successfulFirstFetch: Bool = false
        var timeFetched: Date?
    }
}

public class CacheExistsDsl<DataType: Any> {
    internal var props = Props<DataType>()

    public func cache(_ cache: DataType) {
        props = Props()
        props.cache = cache
    }

    public func fetching() {
        let oldCache = props.cache

        props = Props()
        props.cache = oldCache
        props.fetching = true
    }

    public func failedFetch(error: Error) {
        let oldCache = props.cache

        props = Props()
        props.cache = oldCache
        props.errorDuringFetch = error
    }

    public func successfulFetch(timeFetched: Date) {
        let oldCache = props.cache

        props = Props()
        props.cache = oldCache
        props.successfulFetch = true
        props.successfulFetchTime = timeFetched
    }

    internal struct Props<DataType: Any> {
        var cache: DataType?
        var fetching: Bool = false
        var errorDuringFetch: Error?
        var successfulFetch: Bool = false
        var successfulFetchTime: Date?
    }
}
