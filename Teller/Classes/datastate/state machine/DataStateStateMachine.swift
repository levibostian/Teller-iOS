import Foundation

/**
 Finite state machine for the state of data that is fetched from an online location.

 This file is used internally to keep track and enforce the changing of states that online data can go through.

 The file is designed to begin with an empty state at the constructor. Then via a list of functions, change the state of data. If a function throws an error, it is an illegal traversal through the state machine. If you get an DataState instance back from a function, you have successfully changed the state of data.
 */
internal class DataStateStateMachine<Data: Any> {
    /**
     DataStateMachine is meant to be immutable. It represents that state machine of an instance of DataState (which is also immutable).
     */
    fileprivate let noCacheExistsStateMachine: NoCacheStateMachine?
    fileprivate let cacheExistsStateMachine: CacheStateMachine<Data>?
    fileprivate let fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine?

    fileprivate let requirements: RepositoryRequirements

    private init(requirements: RepositoryRequirements,
                 noCacheExistsStateMachine: NoCacheStateMachine?,
                 cacheExistsStateMachine: CacheStateMachine<Data>?,
                 fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine?) {
        self.noCacheExistsStateMachine = noCacheExistsStateMachine
        self.cacheExistsStateMachine = cacheExistsStateMachine
        self.fetchingFreshCacheStateMachine = fetchingFreshCacheStateMachine
        self.requirements = requirements
    }

    // MARK: - Constructors. The 2 starting nodes in state machine.

    class func noCacheExists(requirements: RepositoryRequirements) -> CacheState<Data> {
        let dataStateMachine = DataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: NoCacheStateMachine.noCacheExists(), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return CacheState(cacheExists: false,
                          cache: nil,
                          cacheAge: nil,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    class func cacheExists(requirements: RepositoryRequirements, lastTimeFetched: Date) -> CacheState<Data> {
        let cacheExistsStateMachine = CacheStateMachine<Data>.cacheEmpty() // Empty is a placeholder for now but it indicates that a cache does exist for future calls to the state machine.
        let fetchingFreshCacheStateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched)
        let dataStateMachine = DataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: nil, cacheExistsStateMachine: cacheExistsStateMachine, fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return CacheState(cacheExists: true,
                          cache: nil,
                          cacheAge: lastTimeFetched,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    // MARK: - Functions to change nodes in state machine

    func firstFetch() throws -> CacheState<Data> {
        guard let noCacheStateMachine = noCacheExistsStateMachine else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: noCacheStateMachine.fetching(), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return CacheState(cacheExists: false,
                          cache: nil,
                          cacheAge: nil,
                          isRefreshing: true,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    func errorFirstFetch(error: Error) throws -> CacheState<Data> {
        guard let noCacheStateMachine = noCacheExistsStateMachine, noCacheStateMachine.isFetching else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: noCacheStateMachine.failedFetching(error: error), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return CacheState(cacheExists: false,
                          cache: nil,
                          cacheAge: nil,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: error)
    }

    func successfulFirstFetch(timeFetched: Date) throws -> CacheState<Data> {
        guard let noCacheStateMachine = noCacheExistsStateMachine, noCacheStateMachine.isFetching else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil, // Cache now exists, no remove this state machine. We will no longer be able to go back to these nodes.
                                                     cacheExistsStateMachine: CacheStateMachine.cacheEmpty(), // empty is like a placeholder.
                                                     fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: timeFetched))

        return CacheState(cacheExists: true,
                          cache: nil,
                          cacheAge: timeFetched,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: true,
                          justFinishedFirstFetch: true,
                          refreshError: nil)
    }

    func cacheIsEmpty() throws -> CacheState<Data> {
        guard cacheExistsStateMachine != nil, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil,
                                                     cacheExistsStateMachine: CacheStateMachine.cacheEmpty(),
                                                     fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return CacheState(cacheExists: true,
                          cache: nil,
                          cacheAge: fetchingFreshCacheStateMachine.lastTimeFetched,
                          isRefreshing: fetchingFreshCacheStateMachine.isFetching,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    func cachedData(_ cache: Data) throws -> CacheState<Data> {
        guard cacheExistsStateMachine != nil, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil,
                                                     cacheExistsStateMachine: CacheStateMachine.cacheExists(cache),
                                                     fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return CacheState(cacheExists: true,
                          cache: cache,
                          cacheAge: fetchingFreshCacheStateMachine.lastTimeFetched,
                          isRefreshing: fetchingFreshCacheStateMachine.isFetching,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    func fetchingFreshCache() throws -> CacheState<Data> {
        guard let cacheStateMachine = cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil,
                                                     cacheExistsStateMachine: cacheStateMachine,
                                                     fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.fetching())

        return CacheState(cacheExists: true,
                          cache: cacheStateMachine.cache,
                          cacheAge: fetchingFreshCacheStateMachine.lastTimeFetched,
                          isRefreshing: true,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }

    func failFetchingFreshCache(_ error: Error) throws -> CacheState<Data> {
        guard let cacheStateMachine = cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine, fetchingFreshCacheStateMachine.isFetching else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil,
                                                     cacheExistsStateMachine: cacheStateMachine,
                                                     fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.failedFetching(error))

        return CacheState(cacheExists: true,
                          cache: cacheStateMachine.cache,
                          cacheAge: fetchingFreshCacheStateMachine.lastTimeFetched,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: false,
                          justFinishedFirstFetch: false,
                          refreshError: error)
    }

    func successfulFetchingFreshCache(timeFetched: Date) throws -> CacheState<Data> {
        guard let cacheStateMachine = cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine, fetchingFreshCacheStateMachine.isFetching else {
            throw DataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: description)
        }

        let dataStateMachine = DataStateStateMachine(requirements: requirements,
                                                     noCacheExistsStateMachine: nil,
                                                     cacheExistsStateMachine: cacheStateMachine,
                                                     fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.successfulFetch(timeFetched: timeFetched))

        return CacheState(cacheExists: true,
                          cache: cacheStateMachine.cache,
                          cacheAge: timeFetched,
                          isRefreshing: false,
                          requirements: requirements,
                          stateMachine: dataStateMachine,
                          justFinishedSuccessfulRefresh: true,
                          justFinishedFirstFetch: false,
                          refreshError: nil)
    }
}

extension DataStateStateMachine: CustomStringConvertible {
    var description: String {
        return "State of machine: \(noCacheExistsStateMachine?.description ?? "") \(cacheExistsStateMachine?.description ?? "") \(fetchingFreshCacheStateMachine?.description ?? "")"
    }
}

// Instead of calling `fatalError`, we throw errors instead of places the state of DataState is not possible.
internal enum DataStateStateMachineError: Swift.Error {
    // With the current state of DataState, you cannot go to this state. Refer to the state machine to see what is valid.
    case nodeNotPossiblePathInStateMachine(stateOfMachine: String)
}

extension DataStateStateMachineError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nodeNotPossiblePathInStateMachine(let stateOfMachine):
            return "Node not possible path in state machine with current state of machine: \(stateOfMachine)"
        }
    }
}
