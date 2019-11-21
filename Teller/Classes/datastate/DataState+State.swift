import Foundation

extension DataState {
    public enum CacheState {
        case cacheEmpty(fetched: Date)
        case cacheData(data: DataType, fetched: Date)
    }

    public enum NoCacheState {
        case noCache
        case firstFetchOfData
        /**
         * @param errorDuringFetch Error that occurred during the fetch of getting first set of cacheData. It is up to you to capture this error and determine how to show it to the user. It's best practice that when there is an error here, you will dismiss a loading UI if you are showing one since [firstFetchOfData] was called before.
         */
        case finishedFirstFetchOfData(errorDuringFetch: Error?)
    }

    public enum FetchingFreshDataState {
        case fetchingFreshCacheData
        /**
         * Fetching of fresh data to put into the cache has been completed successfully or not. If [errorDuringFetch] is not null, then it was a fail if it is null it was successful.
         *
         * It's a best practice to show a UI to the user when data is done being fetched. Here is a tip for you: Sometimes in your app, a fetch can be very fast. It's not a good idea to show a UI to your user during fetching (when [fetchingFreshCacheData] was called) that says something like "Syncing your profile..." and then when [finishedFetchingFreshCacheData] gets called you change the UI to "Done!". What if that network call to fetch fresh data took 0.5 seconds? The user will see a message "Done!" and wonder, "What is done?!" It's recommended to use more descriptive messages such as "Your profile is up-to-date" or have a progress dialog that fades away to indicate the sync is complete and use the [cacheData] `fetched` parameter to show the user that data is only seconds old and has been fetched successfully. This may sounds complex but think of this while developing: If my user does not see the UI I show them when [fetchingFreshCacheData] is called but they see the UI when [finishedFetchingFreshCacheData] is called, will they be confused?
         *
         * @param errorDuringFetch Error that occurred during the fetch of getting first set of cacheData. It is up to you to capture this error and determine how to show it to the user. Since it is during the fetch only, it's best practice here to show this error to the user, but in a UI independent from showing the empty or cached data UI since [cacheEmpty] or [cacheData] will have been called as well in the listener. If you have a situation where an error occur during fetching fresh data but it's not super important to show to the user, it's something you only want to show for a few seconds and then dismiss, or you need to show the user in a UI that forces them to acknowledge it, it's best practice for you to create a [Throwable] subclass and return that in [Repository.FetchResponse.fail] which will then show up here. You can then parse the [Throwable] subclass in your listener to determine what to do with the error. It's also best practice to create custom views/custom dialog fragments to handle errors so you only need to write code once to handle specific errors across your app.
         */
        case finishedFetchingFreshCacheData(errorDuringFetch: Error?)
    }

    /**
     * This is usually used in the UI of an app to display cacheData to a user.
     *
     * Using this function, you can get the state of the cacheData as well as handle errors that may have happened with cacheData (during fetching fresh cacheData or reading the cacheData off the device) or get the status of fetching fresh new cacheData.
     *
     * Use a switch statement to get the states that you care about.
     */
    public func cacheState() -> CacheState? {
        // state of cache could be none() which is represented as cache exists. Therefore, make sure that last time fetched is not null before moving forward to indicate state is not none.
        guard !noCacheExists, let lastTimeFetched = self.lastTimeFetched else {
            return nil
        }

        if let data = self.cacheData {
            return CacheState.cacheData(data: data, fetched: lastTimeFetched)
        } else {
            return CacheState.cacheEmpty(fetched: lastTimeFetched)
        }
    }

    /**
     * This is usually used in the UI of an app to display cacheData to a user.
     *
     * Using this function, you can get the state of the cacheData as well as handle errors that may have happened with cacheData (during fetching fresh cacheData or reading the cacheData off the device) or get the status of fetching fresh new cacheData.
     *
     * Use a switch statement to get the states that you care about.
     */
    public func noCacheState() -> NoCacheState? {
        if justCompletedSuccessfulFirstFetch {
            return NoCacheState.finishedFirstFetchOfData(errorDuringFetch: nil)
        }
        if fetchingForFirstTime {
            return NoCacheState.firstFetchOfData
        }
        if let errorDuringFetch = self.errorDuringFirstFetch {
            return NoCacheState.finishedFirstFetchOfData(errorDuringFetch: errorDuringFetch)
        }
        if noCacheExists {
            return NoCacheState.noCache
        }
        return nil
    }

    /**
     * This is usually used in the UI of an app to display cacheData to a user.
     *
     * Using this function, you can get the state of the cacheData as well as handle errors that may have happened with cacheData (during fetching fresh cacheData or reading the cacheData off the device) or get the status of fetching fresh new cacheData.
     *
     * Use a switch statement to get the states that you care about.
     */
    public func fetchingFreshDataState() -> FetchingFreshDataState? {
        if isFetchingFreshData {
            return FetchingFreshDataState.fetchingFreshCacheData
        }
        if justCompletedSuccessfullyFetchingFreshData {
            return FetchingFreshDataState.finishedFetchingFreshCacheData(errorDuringFetch: errorDuringFetch)
        }
        return nil
    }
}

extension DataState.CacheState: Equatable where DataType: Equatable {
    public static func == (lhs: DataState<DataType>.CacheState, rhs: DataState<DataType>.CacheState) -> Bool {
        switch (lhs, rhs) {
        case (let .cacheEmpty(data1), .cacheEmpty(let data2)):
            return data1 == data2
        case (let .cacheData(data1), .cacheData(let data2)):
            return data1 == data2
        default:
            return false
        }
    }
}

extension DataState.NoCacheState: Equatable where DataType: Equatable {
    public static func == (lhs: DataState<DataType>.NoCacheState, rhs: DataState<DataType>.NoCacheState) -> Bool {
        switch (lhs, rhs) {
        case (.firstFetchOfData, .firstFetchOfData), (.noCache, .noCache):
            return true
        case (let .finishedFirstFetchOfData(error1), .finishedFirstFetchOfData(let error2)):
            return ErrorsUtil.areErrorsEqual(lhs: error1, rhs: error2)
        default:
            return false
        }
    }
}

extension DataState.FetchingFreshDataState: Equatable where DataType: Equatable {
    public static func == (lhs: DataState<DataType>.FetchingFreshDataState, rhs: DataState<DataType>.FetchingFreshDataState) -> Bool {
        switch (lhs, rhs) {
        case (.fetchingFreshCacheData, .fetchingFreshCacheData):
            return true
        case (let .finishedFetchingFreshCacheData(error1), .finishedFetchingFreshCacheData(let error2)):
            return ErrorsUtil.areErrorsEqual(lhs: error1, rhs: error2)
        default:
            return false
        }
    }
}
