//
//  OnlineDataStateStateMachine.swift
//  Teller
//
//  Created by Levi Bostian on 11/28/18.
//

import Foundation

/**
 Finite state machine for the state of data that is fetched from an online location.

 This file is used internally to keep track and enforce the changing of states that online data can go through.

 The file is designed to begin with an empty state at the constructor. Then via a list of functions, change the state of data. If a function throws an error, it is an illegal traversal through the state machine. If you get an OnlineDataState instance back from a function, you have successfully changed the state of data.
 */
internal class OnlineDataStateStateMachine<Data: Any> {

    /**
     OnlineDataStateMachine is meant to be immutable. It represents that state machine of an instance of OnlineDataState (which is also immutable).
     */
    fileprivate let noCacheExistsStateMachine: NoCacheStateMachine?
    fileprivate let cacheExistsStateMachine: CacheStateMachine<Data>?
    fileprivate let fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine?

    fileprivate let requirements: OnlineRepositoryGetDataRequirements

    private init(requirements: OnlineRepositoryGetDataRequirements,
                 noCacheExistsStateMachine: NoCacheStateMachine?,
                 cacheExistsStateMachine: CacheStateMachine<Data>?,
                 fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine?) {
        self.noCacheExistsStateMachine = noCacheExistsStateMachine
        self.cacheExistsStateMachine = cacheExistsStateMachine
        self.fetchingFreshCacheStateMachine = fetchingFreshCacheStateMachine
        self.requirements = requirements
    }

    // MARK - Constructors. The 2 starting nodes in state machine.

    class func noCacheExists(requirements: OnlineRepositoryGetDataRequirements) -> OnlineDataState<Data> {
        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: NoCacheStateMachine.noCacheExists(), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return OnlineDataState(
            noCacheExists: true,
            fetchingForFirstTime: false,
            cacheData: nil,
            lastTimeFetched: nil,
            isFetchingFreshData: false,
            requirements: requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    class func cacheExists(requirements: OnlineRepositoryGetDataRequirements, lastTimeFetched: Date) -> OnlineDataState<Data> {
        let cacheExistsStateMachine = CacheStateMachine<Data>.cacheEmpty() // Empty is a placeholder for now but it indicates that a cache does exist for future calls to the state machine.
        let fetchingFreshCacheStateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched)
        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: requirements, noCacheExistsStateMachine: nil, cacheExistsStateMachine: cacheExistsStateMachine, fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: nil,
            lastTimeFetched: lastTimeFetched,
            isFetchingFreshData: false,
            requirements: requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    // MARK - Functions to change nodes in state machine

    func firstFetch() throws -> OnlineDataState<Data> {
        guard let noCacheStateMachine = self.noCacheExistsStateMachine else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements, noCacheExistsStateMachine: noCacheStateMachine.fetching(), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return OnlineDataState(
            noCacheExists: true,
            fetchingForFirstTime: true,
            cacheData: nil,
            lastTimeFetched: nil,
            isFetchingFreshData: false,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func errorFirstFetch(error: Error) throws -> OnlineDataState<Data> {
        guard let noCacheStateMachine = self.noCacheExistsStateMachine, noCacheStateMachine.isFetching else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements, noCacheExistsStateMachine: noCacheStateMachine.failedFetching(error: error), cacheExistsStateMachine: nil, fetchingFreshCacheStateMachine: nil)

        return OnlineDataState(
            noCacheExists: true,
            fetchingForFirstTime: false,
            cacheData: nil,
            lastTimeFetched: nil,
            isFetchingFreshData: false,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: error,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func successfulFirstFetch(timeFetched: Date) throws -> OnlineDataState<Data> {
        guard let noCacheStateMachine = self.noCacheExistsStateMachine, noCacheStateMachine.isFetching else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil, // Cache now exists, no remove this state machine. We will no longer be able to go back to these nodes.
                                                                 cacheExistsStateMachine: CacheStateMachine.cacheEmpty(), // empty is like a placeholder.
                                                                 fetchingFreshCacheStateMachine: FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: timeFetched))

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: nil,
            lastTimeFetched: timeFetched,
            isFetchingFreshData: false,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: true,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func cacheIsEmpty() throws -> OnlineDataState<Data> {
        guard self.cacheExistsStateMachine != nil, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil,
                                                                 cacheExistsStateMachine: CacheStateMachine.cacheEmpty(),
                                                                 fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: nil,
            lastTimeFetched: fetchingFreshCacheStateMachine.lastTimeFetched,
            isFetchingFreshData: fetchingFreshCacheStateMachine.isFetching,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func cachedData(_ cache: Data) throws -> OnlineDataState<Data> {
        guard self.cacheExistsStateMachine != nil, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil,
                                                                 cacheExistsStateMachine: CacheStateMachine.cacheExists(cache),
                                                                 fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine)

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: cache,
            lastTimeFetched: fetchingFreshCacheStateMachine.lastTimeFetched,
            isFetchingFreshData: fetchingFreshCacheStateMachine.isFetching,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func fetchingFreshCache() throws -> OnlineDataState<Data> {
        guard let cacheStateMachine = self.cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil,
                                                                 cacheExistsStateMachine: cacheStateMachine,
                                                                 fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.fetching())

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: cacheStateMachine.cache,
            lastTimeFetched: fetchingFreshCacheStateMachine.lastTimeFetched,
            isFetchingFreshData: true,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func failFetchingFreshCache(_ error: Error) throws -> OnlineDataState<Data> {
        guard let cacheStateMachine = self.cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine, fetchingFreshCacheStateMachine.isFetching else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil,
                                                                 cacheExistsStateMachine: cacheStateMachine,
                                                                 fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.failedFetching(error))

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: cacheStateMachine.cache,
            lastTimeFetched: fetchingFreshCacheStateMachine.lastTimeFetched,
            isFetchingFreshData: false,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: error,
            justCompletedSuccessfullyFetchingFreshData: false)
    }

    func successfulFetchingFreshCache(timeFetched: Date) throws -> OnlineDataState<Data> {
        guard let cacheStateMachine = self.cacheExistsStateMachine, let fetchingFreshCacheStateMachine = self.fetchingFreshCacheStateMachine, fetchingFreshCacheStateMachine.isFetching else {
            throw OnlineDataStateStateMachineError.nodeNotPossiblePathInStateMachine(stateOfMachine: self.description)
        }

        let onlineDataStateMachine = OnlineDataStateStateMachine(requirements: self.requirements,
                                                                 noCacheExistsStateMachine: nil,
                                                                 cacheExistsStateMachine: cacheStateMachine,
                                                                 fetchingFreshCacheStateMachine: fetchingFreshCacheStateMachine.successfulFetch(timeFetched: timeFetched))

        return OnlineDataState(
            noCacheExists: false,
            fetchingForFirstTime: false,
            cacheData: cacheStateMachine.cache,
            lastTimeFetched: timeFetched,
            isFetchingFreshData: false,
            requirements: self.requirements,
            stateMachine: onlineDataStateMachine,
            errorDuringFirstFetch: nil,
            justCompletedSuccessfulFirstFetch: false,
            errorDuringFetch: nil,
            justCompletedSuccessfullyFetchingFreshData: true)
    }

}

extension OnlineDataStateStateMachine: CustomStringConvertible {

    var description: String {
        return "State of machine: \(self.noCacheExistsStateMachine?.description ?? "") \(self.cacheExistsStateMachine?.description ?? "") \(self.fetchingFreshCacheStateMachine?.description ?? "")"
    }

}

// Instead of calling `fatalError`, we throw errors instead of places the state of OnlineDataState is not possible.
internal enum OnlineDataStateStateMachineError: Swift.Error {

    // With the current state of OnlineDataState, you cannot go to this state. Refer to the state machine to see what is valid.
    case nodeNotPossiblePathInStateMachine(stateOfMachine: String)

}

extension OnlineDataStateStateMachineError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .nodeNotPossiblePathInStateMachine(let stateOfMachine):
            return "Node not possible path in state machine with current state of machine: \(stateOfMachine)"
        }
    }

}
