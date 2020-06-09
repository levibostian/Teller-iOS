import Foundation

/**
 Holds the current state of data that is obtained via a network call. This data structure is meant to be passed out of Teller and to the application using Teller so it can parse it and display the data representation in the app.

 The data state is *not* manipulated here. It is only stored.

 Data in apps are in 1 of 3 different types of state:

 1. Cache data does not exist. It has never been attempted to be fetched or it has been attempted but failed and needs to be attempted again.
 2. Data has been cached in the app and is either empty or not.
 3. A cache exists, and we are fetching fresh data to update the cache.
 */
public class CacheState<CacheType: Any> {
    public let cacheExists: Bool
    public let cache: CacheType?
    public let cacheAge: Date?
    public let isRefreshing: Bool
    public let requirements: RepositoryRequirements?
    internal let stateMachine: DataStateStateMachine<CacheType>?

    // To prevent the end user getting spammed like crazy with UI messages of the same error or same status of data, the following properties should be set once in the constuctor and then for future state calls, negate them.
    public let justFinishedSuccessfulRefresh: Bool
    public let justFinishedFirstFetch: Bool
    public let refreshError: Error?

    public var isFirstFetch: Bool {
        return !cacheExists && isRefreshing
    }

    internal init(cacheExists: Bool,
                  cache: CacheType?,
                  cacheAge: Date?,
                  isRefreshing: Bool,
                  requirements: RepositoryRequirements?,
                  stateMachine: DataStateStateMachine<CacheType>?,
                  justFinishedSuccessfulRefresh: Bool,
                  justFinishedFirstFetch: Bool,
                  refreshError: Error?) {
        self.cacheExists = cacheExists
        self.cache = cache
        self.cacheAge = cacheAge
        self.isRefreshing = isRefreshing
        self.requirements = requirements
        self.stateMachine = stateMachine
        self.justFinishedSuccessfulRefresh = justFinishedSuccessfulRefresh
        self.justFinishedFirstFetch = justFinishedFirstFetch
        self.refreshError = refreshError
    }

    internal var isNone: Bool {
        return cacheExists && cacheAge == nil
    }

    internal func change() -> DataStateStateMachine<CacheType> {
        return stateMachine!
    }

    /**
     Used to take a cache and use that to convert to a different type. *Not used internally* in the library. Only used when observing a cache and you want to be able to conver it to another type.
     */
    public func convert<NewCache: Any>(_ convert: (CacheType?) -> NewCache?) -> CacheState<NewCache> {
        let newCache: NewCache? = convert(cache)

        /// Notice that because this function is not used internally in the library, we provide `nil` as the state machine because that does not matter.
        return CacheState<NewCache>(cacheExists: cacheExists,
                                    cache: newCache,
                                    cacheAge: cacheAge,
                                    isRefreshing: isRefreshing,
                                    requirements: requirements,
                                    stateMachine: nil,
                                    justFinishedSuccessfulRefresh: justFinishedSuccessfulRefresh,
                                    justFinishedFirstFetch: justFinishedFirstFetch,
                                    refreshError: refreshError)
    }

    // MARK: - Intializers. Use these constructors to construct the initial state of this immutable object.

    /**
     This constructor is meant to be more of a placeholder. It's having "no state". This exists for internal purposes

     No state means cache exists, but time last fetched is nil.
     */
    internal static func none() -> CacheState {
        return CacheState(cacheExists: true,
                          cache: nil,
                          cacheAge: nil,
                          isRefreshing: false,
                          requirements: nil,
                          stateMachine: nil,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }
}

extension CacheState: Equatable where CacheType: Equatable {
    public static func == (lhs: CacheState, rhs: CacheState) -> Bool {
        return lhs.cacheExists == rhs.cacheExists &&
            lhs.cache == rhs.cache &&
            lhs.isRefreshing == rhs.isRefreshing &&
            lhs.cacheAge?.timeIntervalSince1970 == rhs.cacheAge?.timeIntervalSince1970 &&
            lhs.requirements?.tag == rhs.requirements?.tag &&
            lhs.justFinishedSuccessfulRefresh == rhs.justFinishedSuccessfulRefresh &&
            lhs.justFinishedFirstFetch == rhs.justFinishedFirstFetch &&
            ((lhs.refreshError != nil && rhs.refreshError != nil) || (lhs.refreshError == nil && rhs.refreshError == nil))
    }
}
