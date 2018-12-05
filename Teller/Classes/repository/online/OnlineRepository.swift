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
    internal let observeCacheQueue = DispatchQueue(label: "observeCacheScheduler")

    internal var currentStateOfData: OnlineDataStateBehaviorSubject<DataSource.Cache> = OnlineDataStateBehaviorSubject() // This is important to never be nil so that we can call `observe` on this class and always be able to listen.

    internal var refreshManager: AppOnlineRepositoryRefreshManager<DataSource.FetchResult>? = nil {
        didSet {
            refreshManager?.delegate = self
        }
    }
    
    /**
     If requirements is set to nil, we will stop observing the cache changes and reset the state of data to nil.
     */
    public var requirements: DataSource.GetDataRequirements? = nil {
        didSet {
            // 1. Cancel observing cache so no more reading of cache updates can happen.
            // 2. Cancel refreshing so no fetch can finish.
            // 3. Set curentStateOfData to something so anyone observing does not think they are still observing old requirements (old data).
            // 4. Start everything up again.

            self.refreshManager = nil // cancel current refresh
            self.observeCacheDisposable?.dispose()

            if let requirements = requirements {
                self.refreshManager = AppOnlineRepositoryRefreshManager()

                if self.syncStateManager.hasEverFetchedData(tag: requirements.tag) {
                    self.currentStateOfData.resetToCacheState(requirements: requirements, lastTimeFetched: self.syncStateManager.lastTimeFetchedData(tag: requirements.tag)!)
                    beginObservingCachedData(requirements: requirements)
                } else {
                    self.currentStateOfData.resetToNoCacheState(requirements: requirements)
                    // When we set new requirements, we want to fetch for first time if have never been done before. Example: paging data. If we go to a new page we have never gotten before, we want to fetch that data for the first time.
                    _ = try! self.refresh(force: false)
                        .subscribeOn(self.schedulersProvider.background)
                        .subscribe()
                }
            } else {
                self.currentStateOfData.resetStateToNone()
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
        refreshManager = nil

        currentStateOfData.subject.on(.completed) // By disposing below, `.completed` does not get sent automatically. We must send ourselves. Alert whoever is observing this repository to know the sequence has completed.
        currentStateOfData.subject.dispose()

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
        guard let requirements = self.requirements, let refreshManager = self.refreshManager else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }

        if (force || !self.syncStateManager.hasEverFetchedData(tag: requirements.tag) || self.syncStateManager.isDataTooOld(tag: requirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)) {

            return refreshManager.refresh(task: self.dataSource.fetchFreshData(requirements: requirements))
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
            .subscribe(onNext: { [weak self] (cache: DataSource.Cache) in
                guard let self = self else { return }

                let needsToFetchFreshData = self.syncStateManager.isDataTooOld(tag: requirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)

                if (self.dataSource.isDataEmpty(cache)) {
                    self.currentStateOfData.changeState({ try! $0.cacheIsEmpty() })
                } else {
                    self.currentStateOfData.changeState({ try! $0.cachedData(cache) })
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
     * The state of the Observable returned from this function is maintained by the OnlineRepository. When the OnlineRepository `deinit` is called, all observers will be disposed.
     * When you subscribe to the returned `Observable`, you will receive a result immediately with the current state of the data when you subscribe (even if there is "no state").
     
     - Returns: A RxSwift Observable<OnlineDataState<Cache>> instance that gets notified when the state of the cached data changes.
     */
    public final func observe() -> Observable<OnlineDataState<DataSource.Cache>> {
        if self.requirements != nil {
            // Trigger a refresh to help keep data up-to-date.
            _ = try! self.refresh(force: false)
                .subscribeOn(self.schedulersProvider.background)
                .subscribe()
        }
        
        return self.currentStateOfData.subject
    }
    
}

extension OnlineRepository: OnlineRepositoryRefreshManagerDelegate {

    func refreshBegin() {
        if !self.syncStateManager.hasEverFetchedData(tag: self.requirements!.tag) {
            self.currentStateOfData.changeState({ try! $0.firstFetch() })
        } else {
            self.currentStateOfData.changeState({ try! $0.fetchingFreshCache() })
        }
    }

    func refreshComplete<FetchResponseData>(_ response: FetchResponse<FetchResponseData>) {
        if let fetchError = response.failure {
            // Note: Make sure that you **do not** beginObservingCachedData() if there is a failure and we have never fetched data successfully before. We cannot begin observing cached data until we know for sure a cache actually exists!
            if !self.syncStateManager.hasEverFetchedData(tag: requirements!.tag) {
                self.currentStateOfData.changeState({ try! $0.errorFirstFetch(error: fetchError) })
            } else {
                self.currentStateOfData.changeState({ try! $0.failFetchingFreshCache(fetchError) })
            }
        } else {
            // Below is some interesting code I need to explain.
            // In iOS, CoreData is not Observable (that I know of) by RxSwift but other DBs like Realm are.
            // To be more universal, I am triggering an Observable onNext() update for the developer myself by disposing of     the previous `cachedData` `Observable` before saving data, saving data, and then starting up the `Observable` again. This way, we always get the newest cached data triggered no matter what the dev is using.
            // Also, `refresh` is called if data has been fetched before or has never been called before. After the first fetch is ever successful, we need to begin observing cached data for the first time anyway. So call it here.
            self.observeCacheDisposable?.dispose() // Avoid Observable trigger from cached data if it decides to happen.
            let newCache: DataSource.FetchResult = response.data as! DataSource.FetchResult
            self.dataSource.saveData(newCache)
            let hasEverFetchedDataBefore = self.syncStateManager.hasEverFetchedData(tag: requirements!.tag) // Get value before calling `updateAgeOfData`.
            self.syncStateManager.updateAgeOfData(tag: requirements!.tag)

            if !hasEverFetchedDataBefore {
                self.currentStateOfData.changeState({ try! $0.successfulFirstFetch(timeFetched: self.syncStateManager.lastTimeFetchedData(tag: requirements!.tag)!) })
            } else {
                self.currentStateOfData.changeState({ try! $0.successfulFetchingFreshCache(timeFetched: Date()) })
            }

            // Must do after changing the state of data or else it will fail from not being in a "has cache" state.
            self.beginObservingCachedData(requirements: requirements!)
        }
    }

    func refreshFail(_ error: Error) {
        // This is an Rx error. It should never happen.
        fatalError(error.localizedDescription)
    }


}
