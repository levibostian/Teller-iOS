import Foundation

/**
 Holds the current state of data that is obtained via a network call. This data structure is meant to be passed out of Teller and to the application using Teller so it can parse it and display the data representation in the app.

 The data state is *not* manipulated here. It is only stored.

 Data in apps are in 1 of 3 different types of state:

 1. Cache data does not exist. It has never been attempted to be fetched or it has been attempted but failed and needs to be attempted again.
 2. Data has been cached in the app and is either empty or not.
 3. A cache exists, and we are fetching fresh data to update the cache.
 */
public struct DataState<DataType: Any> {
    let noCacheExists: Bool
    var cacheExists: Bool { return !noCacheExists }
    let fetchingForFirstTime: Bool
    let cacheData: DataType?
    let lastTimeFetched: Date?
    let isFetchingFreshData: Bool

    let requirements: RepositoryRequirements?
    internal let stateMachine: DataStateStateMachine<DataType>?

    // To prevent the end user getting spammed like crazy with UI messages of the same error or same status of data, the following properties should be set once in the constuctor and then for future state calls, negate them.
    let errorDuringFirstFetch: Error?
    let justCompletedSuccessfulFirstFetch: Bool
    let errorDuringFetch: Error?
    let justCompletedSuccessfullyFetchingFreshData: Bool

    /**
     Used to take a cache and use that to convert to a different type. *Not used internally* in the library. Only used when observing a cache and you want to be able to conver it to another type.
     */
    public func convert<NewDataType: Any>(_ convert: (DataType?) -> NewDataType?) -> DataState<NewDataType> {
        let newCache: NewDataType? = convert(cacheData)

        /// Notice that because this function is not used internally in the library, we provide `nil` as the state machine because that does not matter.
        return DataState<NewDataType>(noCacheExists: noCacheExists,
                                      fetchingForFirstTime: fetchingForFirstTime,
                                      cacheData: newCache,
                                      lastTimeFetched: lastTimeFetched,
                                      isFetchingFreshData: isFetchingFreshData,
                                      requirements: requirements,
                                      stateMachine: nil,
                                      errorDuringFirstFetch: errorDuringFirstFetch,
                                      justCompletedSuccessfulFirstFetch: justCompletedSuccessfulFirstFetch,
                                      errorDuringFetch: errorDuringFetch,
                                      justCompletedSuccessfullyFetchingFreshData: justCompletedSuccessfullyFetchingFreshData)
    }

    internal var isNone: Bool {
        return cacheExists && lastTimeFetched == nil
    }

    /**
     Used to change the state of data.
     */
    internal func change() -> DataStateStateMachine<DataType> {
        return stateMachine!
    }

    // MARK: - Intializers. Use these constructors to construct the initial state of this immutable object.

    /**
     This constructor is meant to be more of a placeholder. It's having "no state".

     No state means cache exists, but time last fetched is nil.
     */
    internal static func none() -> DataState {
        return DataState(noCacheExists: false,
                         fetchingForFirstTime: false,
                         cacheData: nil,
                         lastTimeFetched: nil,
                         isFetchingFreshData: false,
                         requirements: nil,
                         stateMachine: nil,
                         errorDuringFirstFetch: nil,
                         justCompletedSuccessfulFirstFetch: false,
                         errorDuringFetch: nil,
                         justCompletedSuccessfullyFetchingFreshData: false)
    }
}

extension DataState: Equatable where DataType: Equatable {
    public static func == (lhs: DataState<DataType>, rhs: DataState<DataType>) -> Bool {
        return lhs.noCacheExists == rhs.noCacheExists &&
            lhs.fetchingForFirstTime == rhs.fetchingForFirstTime &&
            lhs.cacheData == rhs.cacheData &&
            lhs.isFetchingFreshData == rhs.isFetchingFreshData &&
            lhs.lastTimeFetched?.timeIntervalSince1970 == rhs.lastTimeFetched?.timeIntervalSince1970 &&

            lhs.requirements?.tag == rhs.requirements?.tag &&

            ErrorsUtil.areErrorsEqual(lhs: lhs.errorDuringFirstFetch, rhs: rhs.errorDuringFirstFetch) &&
            lhs.justCompletedSuccessfulFirstFetch == rhs.justCompletedSuccessfulFirstFetch &&
            lhs.justCompletedSuccessfullyFetchingFreshData == rhs.justCompletedSuccessfullyFetchingFreshData &&
            ErrorsUtil.areErrorsEqual(lhs: lhs.errorDuringFetch, rhs: rhs.errorDuringFetch)
    }
}
