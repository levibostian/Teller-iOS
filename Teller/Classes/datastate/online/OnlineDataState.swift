//
//  OnlineDataState.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

/**
 * Data in apps are in 1 of 3 different types of state:
 *
 * 1. Data does not exist. It has never been obtained before.
 * 2. It is empty. Data has been obtained before, but there is none.
 * 3. Data exists.
 *
 * This class takes in a type of cacheData to keep state on via generic [DATA] and it maintains the state of that cacheData.
 *
 * Along with the 3 different states cacheData could be in, there are temporary states that cacheData could also be in.
 *
 * * An error occurred with that cacheData.
 * * Fresh cacheData is being fetched for this cacheData. It may be updated soon.
 *
 * The 3 states listed above empty, cacheData, loading are all permanent. Data is 1 of those 3 at all times. Data has this error or fetching status temporarily until someone calls [deliver] one time and then those temporary states are deleted.
 *
 * This class is used in companion with [Repository] and [OnlineStateDataCompoundBehaviorSubject] to maintain the state of cacheData to deliver to someone observing.
 *
 * @property firstFetchOfData When cacheData has never been fetched before for a cacheData type, this is where it all begins. After this, cacheData will be empty or cacheData state.
 * @property errorDuringFetch Says that the [latestError] was caused during the fetching phase.
 */
public struct OnlineDataState<DataType: Any> {

    public let firstFetchOfData: Bool
    public let doneFirstFetchOfData: Bool
    public let isEmpty: Bool
    public let data: DataType?
    public let dataFetched: Date?
    public let errorDuringFirstFetch: Error?
    public let isFetchingFreshData: Bool
    public let doneFetchingFreshData: Bool
    public let errorDuringFetch: Error?
    public let getDataRequirements: OnlineRepositoryGetDataRequirements

    private init(firstFetchOfData: Bool = false,
                 doneFirstFetchOfData: Bool = false,
                 isEmpty: Bool = false,
                 data: DataType? = nil,
                 dataFetched: Date? = nil,
                 errorDuringFirstFetch: Error? = nil,
                 isFetchingFreshData: Bool = false,
                 doneFetchingFreshData: Bool = false,
                 errorDuringFetch: Error? = nil,
                 getDataRequirements: OnlineRepositoryGetDataRequirements) {
        self.firstFetchOfData = firstFetchOfData
        self.doneFirstFetchOfData = doneFirstFetchOfData
        self.isEmpty = isEmpty
        self.data = data
        self.dataFetched = dataFetched
        self.errorDuringFirstFetch = errorDuringFirstFetch
        self.isFetchingFreshData = isFetchingFreshData
        self.doneFetchingFreshData = doneFetchingFreshData
        self.errorDuringFetch = errorDuringFetch
        self.getDataRequirements = getDataRequirements
    }

    // Use these constructors to construct the initial state of this immutable object. Use the functions
    public static func firstFetchOfData(getDataRequirements: OnlineRepositoryGetDataRequirements) -> OnlineDataState {
        return OnlineDataState(firstFetchOfData: true, getDataRequirements: getDataRequirements)
    }

    public static func isEmpty(getDataRequirements: OnlineRepositoryGetDataRequirements) -> OnlineDataState {
        return OnlineDataState(isEmpty: true, getDataRequirements: getDataRequirements)
    }

    public static func data(data: DataType, dataFetched: Date, getDataRequirements: OnlineRepositoryGetDataRequirements) -> OnlineDataState {
        return OnlineDataState(data: data, dataFetched: dataFetched, getDataRequirements: getDataRequirements)
    }

    /**
     * Tag on an error to this cacheData. Errors could be an error fetching fresh cacheData or reading cacheData off the device. The errors should have to deal with this cacheData, not some generic error encountered in the app.
     *
     * @return New immutable instance of [OnlineDataState]
     */
    public func doneFirstFetch(error: Error?) -> OnlineDataState {
        return OnlineDataState(
            // Done fetching data
            firstFetchOfData: false,
            // Done with first fetch of data.
            doneFirstFetchOfData: true,
            isEmpty: self.isEmpty,
            data: self.data,
            dataFetched: self.dataFetched,
            // Setting if error.
            errorDuringFirstFetch: error,
            isFetchingFreshData: self.isFetchingFreshData,
            doneFetchingFreshData: self.doneFetchingFreshData,
            // Set nil to avoid calling the listener error() multiple times.
            errorDuringFetch: nil,
            getDataRequirements: self.getDataRequirements)
    }

    /**
     * Set the status of this cacheData as fetching fresh cacheData.
     *
     * @return New immutable instance of [OnlineDataState]
     */
    public func fetchingFreshData() -> OnlineDataState {
        if (self.firstFetchOfData) {
            fatalError("The state of cacheData is saying you are already fetching for the first time. You cannot fetch for first time and fetch after cache.")
        }

        return OnlineDataState(
            firstFetchOfData: self.firstFetchOfData,
            doneFirstFetchOfData: self.doneFirstFetchOfData,
            isEmpty: self.isEmpty,
            data: self.data,
            dataFetched: self.dataFetched,
            // Set nil to avoid calling the listener error() multiple times.
            errorDuringFirstFetch: nil,
            // Is fetching fresh data
            isFetchingFreshData: true,
            doneFetchingFreshData: self.doneFetchingFreshData,
            // Set nil to avoid calling the listener error() multiple times.
            errorDuringFetch: nil,
            getDataRequirements: self.getDataRequirements)
    }
    
    /**
     * Set the status of this cacheData as done fetching fresh cacheData.
     *
     * @return New immutable instance of [OnlineDataState]
     */
    public func doneFetchingFreshData(errorDuringFetch: Error?) -> OnlineDataState {
        if (self.firstFetchOfData) {
            fatalError("Call doneFirstFetch() instead. Then all future calls *after* the first fetch will be done using fetchingFreshData() and doneFetchingFreshData().")
        }
    
        return OnlineDataState(
            firstFetchOfData: self.firstFetchOfData,
            doneFirstFetchOfData: self.doneFirstFetchOfData,
            isEmpty: self.isEmpty,
            data: self.data,
            dataFetched: self.dataFetched,
            // Set nil to avoid calling the listener error() multiple times.
            errorDuringFirstFetch: nil,
            // Done fetching
            isFetchingFreshData: false,
            // Done fetching
            doneFetchingFreshData: true,
            // Setting if error
            errorDuringFetch: errorDuringFetch,
            getDataRequirements: self.getDataRequirements)
    }
    
}

extension OnlineDataState: Equatable where DataType: Equatable {
    
    public static func == (lhs: OnlineDataState<DataType>, rhs: OnlineDataState<DataType>) -> Bool {        
        return lhs.firstFetchOfData == rhs.firstFetchOfData &&
            lhs.doneFirstFetchOfData == rhs.doneFirstFetchOfData &&
            lhs.isEmpty == rhs.isEmpty &&
            lhs.data == rhs.data &&
            lhs.dataFetched?.timeIntervalSince1970 == rhs.dataFetched?.timeIntervalSince1970 &&
            ErrorsUtil.areErrorsEqual(lhs: lhs.errorDuringFirstFetch, rhs: rhs.errorDuringFirstFetch) &&
            lhs.isFetchingFreshData == rhs.isFetchingFreshData &&
            lhs.doneFetchingFreshData == rhs.doneFetchingFreshData &&
            ErrorsUtil.areErrorsEqual(lhs: lhs.errorDuringFetch, rhs: rhs.errorDuringFetch) && 
            lhs.getDataRequirements.tag == rhs.getDataRequirements.tag
    }
    
}
