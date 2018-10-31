//
//  OnlineRepositorySyncRunner.swift
//  Teller
//
//  Created by Levi Bostian on 9/16/18.
//

import Foundation
import RxSwift

/**
 Use in your app: 1 instance per 1 instance of OnlineRepositoryDataSource, to observe a OnlineRepositoryDataSource.
 
 1. Initialize an instance of OnlineRepository
 2. Set the `dataSource` property with an instance of OnlineRepositoryDataSource
 3. Call any of the functions below to sync or observe data.
 */
open class OnlineRepository<DataSource: OnlineRepositoryDataSource> {
    
    public let dataSource: DataSource
    internal let syncStateManager: RepositorySyncStateManager
    internal let schedulersProvider: SchedulersProvider
    
    internal var observeCacheDisposable: Disposable? = nil
    internal var currentStateOfDataMulticastDisposable: Disposable? = nil
    internal var currentStateOfDataConnectableObservable: ConnectableObservable<OnlineDataState<DataSource.Cache>>? = nil // TODO remove me if doesnt work.
    internal var currentStateOfData: OnlineDataStateBehaviorSubject<DataSource.Cache>? = nil
    
    public var requirements: DataSource.GetDataRequirements? = nil {
        didSet {
            if let requirements = requirements {
                if self.currentStateOfData == nil {
                    let initialStateOfData = OnlineDataStateBehaviorSubject<DataSource.Cache>(getDataRequirements: requirements)
                    let initialValueStateOfData = try! initialStateOfData.subject.value()
                    self.currentStateOfData = initialStateOfData
                    
                    self.currentStateOfDataConnectableObservable = self.currentStateOfData!.subject.multicast { () -> BehaviorSubject<OnlineDataState<DataSource.Cache>> in
                        return BehaviorSubject(value: initialValueStateOfData)
                    }
                    self.currentStateOfDataMulticastDisposable = self.currentStateOfDataConnectableObservable!.connect()
                }
                
                if self.syncStateManager.hasEverFetchedData(tag: requirements.tag) {
                    beginObservingCachedData(requirements: requirements)
                } else {
                    // When we set new requirements, we want to fetch for first time if have never been done before. Example: paging data. If we go to a new page we have never gotten before, we want to fetch that data for the first time.
                    _ = try! self.refresh(force: false)
                        .subscribeOn(self.schedulersProvider.background)
                        .subscribe()
                }
            }
        }
    }
    
    required public init(dataSource: DataSource) {
        self.dataSource = dataSource
        self.syncStateManager = TellerRepositorySyncStateManager()
        self.schedulersProvider = AppSchedulersProvider()
    }
    
    // init designed for testing purposes. Pass in mocked `syncStateManager` if you wish.
    // The OnlineRepository is designed to *not* perform any behavior until parameters have been set sometime in the future. **Do not** trigger any refresh, observe, etc behavior in init.
    internal init(dataSource: DataSource, syncStateManager: RepositorySyncStateManager, schedulersProvider: SchedulersProvider) {
        self.dataSource = dataSource
        self.syncStateManager = syncStateManager
        self.schedulersProvider = schedulersProvider
    }
    
    deinit {
        currentStateOfData?.subject.on(.completed) // By disposing below, `.completed` does not get sent automatically. We must send ourselves. Alert whoever is observing this repository to know the sequence has completed.
        currentStateOfDataMulticastDisposable?.dispose()
        currentStateOfData?.subject.dispose()
        
        observeCacheDisposable?.dispose()
    }
    
    /**
     ### Manually perform a refresh of the cached data.
     
     Ideal in these scenarios:
     
     * User indicates in the UI they would like to check for new data. Example: `UIRefreshControl` in a `UITableView` indicating to refresh the data.
     * The *first* fetch of data for this repository failed. If the *first* fetch fails, it is on you to refresh or `observe()` again to try again.
     
     First check if cached data is too old (or `force` parameter is `true`) and if so, perform a `fetchFreshData()` call proceeded by `saveData` to save the cache result and then send an update to `observe()` observers about the new state of the cache.
     
     - Returns: A Single<SyncResult> that notifies you asynchronously with how the sync performed (successful or failed).
     - Throws: TellerError.objectPropertiesNotSet if you did not set `requirements` before calling this function.
     */
    public final func refresh(force: Bool) throws -> Single<SyncResult> {
        guard let requirements = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }
        
        if (force || !self.syncStateManager.hasEverFetchedData(tag: requirements.tag) || self.syncStateManager.isDataTooOld(tag: requirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)) {
            return self.dataSource.fetchFreshData(requirements: requirements)
                .do(onSubscribe: { // Do not use `onSubscribed` as it triggers the update *after* the fetch is complete in tests instead of before.
                    if !self.syncStateManager.hasEverFetchedData(tag: requirements.tag) {
                        self.currentStateOfData?.onNextFirstFetchOfData()
                    } else {
                        self.currentStateOfData?.onNextFetchingFreshData()
                    }
                })
                .map({ (fetchResponse: FetchResponse<DataSource.FetchResult>) -> SyncResult in
                    if let fetchError = fetchResponse.failure {
                        // Note: Make sure that you **do not** beginObservingCachedData() if there is a failure and we have never fetched data successfully before. We cannot begin observing cached data until we know for sure a cache actually exists!
                        if !self.syncStateManager.hasEverFetchedData(tag: requirements.tag) {
                            self.currentStateOfData?.onNextDoneFirstFetch(errorDuringFetch: fetchError)
                        } else {
                            self.currentStateOfData?.onNextDoneFetchingFreshData(errorDuringFetch: fetchError)
                        }
                        return SyncResult.fail(fetchResponse.failure!)
                    } else {
                        // Below is some interesting code I need to explain.
                        // In iOS, CoreData is not Observable (that I know of) by RxSwift but other DBs like Realm are.
                        // To be more universal, I am triggering an Observable onNext() update for the developer myself by disposing of the previous `cachedData` `Observable` before saving data, saving data, and then starting up the `Observable` again. This way, we always get the newest cached data triggered no matter what the dev is using.
                        // Also, `refresh` is called if data has been fetched before or has never been called before. After the first fetch is ever successful, we need to begin observing cached data for the first time anyway. So call it here.
                        self.observeCacheDisposable?.dispose() // Avoid Observable trigger from cached data if it decides to happen.
                        self.dataSource.saveData(fetchResponse.data!)
                        let hasEverFetchedDataBefore = self.syncStateManager.hasEverFetchedData(tag: requirements.tag) // Get value before calling `updateAgeOfData`.
                        self.syncStateManager.updateAgeOfData(tag: requirements.tag)
                        self.beginObservingCachedData(requirements: requirements)
                        
                        if !hasEverFetchedDataBefore {
                            self.currentStateOfData?.onNextDoneFirstFetch(errorDuringFetch: nil)
                        } else {
                            self.currentStateOfData?.onNextDoneFetchingFreshData(errorDuringFetch: nil)
                        }
                        
                        return SyncResult.success()
                    }
                })
        } else {
            return Single.just(SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld))
        }
    }
    
    fileprivate func beginObservingCachedData(requirements: DataSource.GetDataRequirements) {
        if (!self.syncStateManager.hasEverFetchedData(tag: requirements.tag)) {
            fatalError("You cannot begin observing cached data until after data has been successfully fetched at least once")
        }
        
        observeCacheDisposable?.dispose()
        
        // I need to subscribe and observe on the UI thread because popular database solutions such as Realm, Core Data all have a "write on background, read on UI" approach. You cannot read on the background and send the read objects to the UI thread. So, we read on the UI.                        
        observeCacheDisposable = self.dataSource.observeCachedData(requirements: requirements)
            .subscribeOn(schedulersProvider.ui)
            .observeOn(schedulersProvider.ui)
            .subscribe(onNext: { (cache: DataSource.Cache) in
                let needsToFetchFreshData = self.syncStateManager.isDataTooOld(tag: requirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)
                
                let lastTimeDataFetched: Date? = self.syncStateManager.lastTimeFetchedData(tag: requirements.tag)
                if (self.dataSource.isDataEmpty(cache)) {
                    self.currentStateOfData?.onNextCacheEmpty(isFetchingFreshData: needsToFetchFreshData, dataFetched: lastTimeDataFetched!)
                } else {
                    self.currentStateOfData?.onNextCachedData(data: cache, dataFetched: lastTimeDataFetched!, isFetchingFreshData: needsToFetchFreshData)
                }
                
                if (needsToFetchFreshData) {
                    _ = try! self.refresh(force: false)
                        .subscribeOn(self.schedulersProvider.background)
                        .subscribe()
                }
            })
    }
    
    /**
     ### Observe changes to the state of data.
     
     **Note**
     * Each time you call this function, it is your responsibility to dispose of the `Observable` returned from this function. Teller does not take care of that for you. Each time you call this function you receive a *new* `Observable` that needs to be disposed on it's own.
     * When you subscribe to the returned `Observable`, you will receive a result immediately with the current state of the data when you subscribe (even if there is "no state").
     
     - Returns: A RxSwift Observable<OnlineDataState<Cache>> instance that gets notified when the state of the cached data changes.
     - Throws: TellerError.objectPropertiesNotSet if you did not set `requirements` before calling this function.
     */
    public final func observe() throws -> Observable<OnlineDataState<DataSource.Cache>> {
        guard let _ = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }
        
        // Trigger a refresh to help keep data up-to-date.
        _ = try self.refresh(force: false)
            .subscribeOn(schedulersProvider.background)
            .subscribe()
        
        return currentStateOfDataConnectableObservable!
    }
    
}
