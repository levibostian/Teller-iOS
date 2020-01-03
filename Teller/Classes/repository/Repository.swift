import Foundation
import RxSwift

/**
 Use in your app: 1 instance per 1 instance of RepositoryDataSource, to observe a RepositoryDataSource.

 1. Initialize an instance of Repository
 2. Set the `dataSource` property with an instance of RepositoryDataSource
 3. Call any of the functions below to sync or observe data.

 Repository is thread safe. Actions called upon for Repository can be performed on any thread.
 */
public class Repository<DataSource: RepositoryDataSource> {
    internal let dataSource: DataSource

    internal let syncStateManager: RepositorySyncStateManager
    internal let schedulersProvider: SchedulersProvider

    internal var observeCacheDisposeBag: CompositeDisposable = CompositeDisposable()
    internal var refreshDisposeBag: CompositeDisposable = CompositeDisposable()

    internal var currentStateOfData: DataStateBehaviorSubject<DataSource.Cache> = DataStateBehaviorSubject() // This is important to never be nil so that we can call `observe` on this class and always be able to listen.

    internal var refreshManager: RepositoryRefreshManager

    /**
     If requirements is set to nil, we will stop observing the cache changes and reset the state of data to nil.
     */
    public var requirements: DataSource.Requirements? {
        willSet {
            let oldValue = requirements

            if let newValue = newValue {
                // We only want to do something when the old and new are not the same. Else, they are the same and ignore the request.
                if oldValue?.tag != newValue.tag {
                    newRequirementsSet(newValue)
                }
            } else {
                // When set requirements to nil, we make the repo "dead"
                stopObservingCache()
                refreshManager.cancelRefresh()
                currentStateOfData.resetStateToNone()
            }
        }
    }

    internal func newRequirementsSet(_ requirements: DataSource.Requirements) {
        // 1. Cancel observing cache so no more reading of cache updates can happen.
        // 2. Cancel refreshing so no fetch can finish.
        // 3. Set curentStateOfData to something so anyone observing does not think they are still observing old requirements (old data).
        // 4. Start everything up again.

        refreshManager.cancelRefresh()
        stopObservingCache()

        if syncStateManager.hasEverFetchedData(tag: requirements.tag) {
            currentStateOfData.resetToCacheState(requirements: requirements, lastTimeFetched: syncStateManager.lastTimeFetchedData(tag: requirements.tag)!)
            beginObservingCachedData(requirements: requirements)
        } else {
            currentStateOfData.resetToNoCacheState(requirements: requirements)
            // When we set new requirements, we want to fetch for first time if have never been done before. Example: paging data. If we go to a new page we have never gotten before, we want to fetch that data for the first time.
            refreshDisposeBag += try! _refresh(force: false, requirements: requirements)
                .subscribeOn(schedulersProvider.background)
                .subscribe()
        }
    }

    public init(dataSource: DataSource) {
        self.dataSource = dataSource
        self.syncStateManager = TellerRepositorySyncStateManager()
        self.schedulersProvider = AppSchedulersProvider()
        self.refreshManager = AppRepositoryRefreshManager()

        postInit()
    }

    // init designed for testing purposes. Pass in mocked `syncStateManager` if you wish.
    // The Repository is designed to *not* perform any behavior until parameters have been set sometime in the future. **Do not** trigger any refresh, observe, etc behavior in init.
    internal init(dataSource: DataSource, syncStateManager: RepositorySyncStateManager, schedulersProvider: SchedulersProvider, refreshManager: RepositoryRefreshManager) {
        self.dataSource = dataSource
        self.syncStateManager = syncStateManager
        self.schedulersProvider = schedulersProvider
        self.refreshManager = refreshManager

        postInit()
    }

    private func postInit() {
        refreshManager.delegate = self
    }

    deinit {
        refreshManager.cancelRefresh()
        refreshDisposeBag.dispose()

        currentStateOfData.subject.on(.completed) // By disposing below, `.completed` does not get sent automatically. We must send ourselves. Alert whoever is observing this repository to know the sequence has completed.
        currentStateOfData.subject.dispose()

        stopObservingCache()
    }

    /**
     ### Manually perform a refresh of the cached data.

     Ideal in these scenarios:

     * User indicates in the UI they would like to check for new data. Example: `UIRefreshControl` in a `UITableView` indicating to refresh the data.
     * The *first* fetch of data for this repository failed. If the *first* fetch fails, it is on you to refresh or `observe()` again to try again.

     First check if cached data is too old (or `force` parameter is `true`) and if so, perform a `fetchFreshCache()` call proceeded by `saveData` to save the cache result and then send an update to `observe()` observers about the new state of the cache.

     - Returns: A Single<RefreshResult> that notifies you asynchronously with how the sync performed (successful or failed).
     - Throws: TellerError.objectPropertiesNotSet if you did not set `requirements` before calling this function.
     */
    public func refresh(force: Bool) throws -> Single<RefreshResult> {
        guard let requirements = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }

        return try _refresh(force: force, requirements: requirements)
    }

    /**
     ### Perform a refresh only if a cache does not yet exist.

     Ideal in these scenarios:
     * App opened for the first time and it cannot operate without a cache.

     - Returns: A Single<RefreshResult> that notifies you asynchronously with how the refresh performed (successful or failed). If a cache exists, RefreshResult.successful will be returned. That way all you need to do is check for `RefreshResult.successful` if a cache exists or not.
     - Throws: TellerError.objectPropertiesNotSet if you did not set `requirements` before calling this function.
     */
    public func refreshIfNoCache() throws -> Single<RefreshResult> {
        guard let requirements = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }

        guard !syncStateManager.hasEverFetchedData(tag: requirements.tag) else {
            return Single.just(RefreshResult.successful)
        }

        return try refresh(force: false)
    }

    private func _refresh(force: Bool, requirements: DataSource.Requirements) throws -> Single<RefreshResult> {
        if force || !syncStateManager.hasEverFetchedData(tag: requirements.tag) || syncStateManager.isCacheTooOld(tag: requirements.tag, maxAgeOfCache: dataSource.maxAgeOfCache) {
            return refreshManager.refresh(task: dataSource.fetchFreshCache(requirements: requirements), requirements: requirements)
        } else {
            return Single.just(.skipped(reason: .dataNotTooOld))
        }
    }

    fileprivate func beginObservingCachedData(requirements: DataSource.Requirements) {
        if !syncStateManager.hasEverFetchedData(tag: requirements.tag) {
            fatalError("You cannot begin observing cached data until after data has been successfully fetched at least once")
        }

        // We need to (1) get the Observable from the data source, (2) query the DB, and (3) perform actions on the queried DB results all in the main thread. So, we will queue up this work on the main thread.
        // I need to subscribe and observe on the UI thread because popular database solutions such as Realm, Core Data all have a "write on background, read on UI" approach. You cannot read on the background and send the read objects to the UI thread. So, we read on the UI.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.stopObservingCache()

            self.observeCacheDisposeBag += self.dataSource.observeCache(requirements: requirements)
                .subscribeOn(self.schedulersProvider.ui)
                .observeOn(self.schedulersProvider.ui)
                .subscribe(onNext: { [weak self, requirements] (cache: DataSource.Cache) in
                    guard let self = self else { return }

                    let needsToFetchFreshCache = self.syncStateManager.isCacheTooOld(tag: requirements.tag, maxAgeOfCache: self.dataSource.maxAgeOfCache)

                    if self.dataSource.isCacheEmpty(cache, requirements: requirements) {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.cacheIsEmpty() }
                    } else {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.cachedData(cache) }
                    }

                    if needsToFetchFreshCache {
                        self.refreshDisposeBag += try! self._refresh(force: false, requirements: requirements)
                            .subscribeOn(self.schedulersProvider.background)
                            .subscribe()
                    }
                })
        }
    }

    /**
     ### Observe changes to the state of data.

     **Note**
     * The state of the Observable returned from this function is maintained by the Repository. When the Repository `deinit` is called, all observers will be disposed.
     * When you subscribe to the returned `Observable`, you will receive a result immediately with the current state of the data when you subscribe (even if there is "no state").

     - Returns: A RxSwift Observable<DataState<Cache>> instance that gets notified when the state of the cached data changes.
     */
    public func observe() -> Observable<DataState<DataSource.Cache>> {
        if let requirements = requirements {
            // Trigger a refresh to help keep data up-to-date.
            refreshDisposeBag += try! _refresh(force: false, requirements: requirements)
                .subscribeOn(schedulersProvider.background)
                .subscribe()
        }

        return currentStateOfData.subject
    }

    private func stopObservingCache() {
        observeCacheDisposeBag.dispose()
        observeCacheDisposeBag = CompositeDisposable()
    }
}

extension Repository: RepositoryRefreshManagerDelegate {
    // called on background thread
    internal func refreshBegin(requirements: RepositoryRequirements) {
        let hasEverFetchedDataBefore = !currentStateOfData.currentState.noCacheExists

        if !hasEverFetchedDataBefore {
            currentStateOfData.changeState(requirements: requirements) { try! $0.firstFetch() }
        } else {
            currentStateOfData.changeState(requirements: requirements) { try! $0.fetchingFreshCache() }
        }
    }

    // called on background thread
    internal func refreshComplete<FetchResponseData, ErrorType>(_ response: FetchResponse<FetchResponseData, ErrorType>, requirements: RepositoryRequirements, onComplete: @escaping () -> Void) {
        let requirements = requirements as! DataSource.Requirements // swiftlint:disable:this force_cast

        switch response {
        case .success(let success):
            let newCache: DataSource.FetchResult = success as! DataSource.FetchResult // swiftlint:disable:this force_cast

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else {
                    return
                }

                let timeFetched = Date()
                let hasEverFetchedDataBefore = !self.currentStateOfData.currentState.noCacheExists

                do {
                    // We need to stop observing cache before saving. saveData() will trigger an onNext() from the cache observable in the dataSource because data is being saved and Observables are supposed to trigger updates like that. The problem is that when we are observing cache in the repository, we trigger a refresh depending on the age of the cache. But as you can see from comments below, we don't want to update the age of the cache until after the save is successful. So, we need to have control over when the cache is observed. We want to read the cache after it is successfully saved and then after we update the state machine and age of cache. Then, the state machine will be in the correct state and the age of cache will not trigger a refresh update automatically.
                    self.stopObservingCache()

                    try self.dataSource.saveCache(newCache, requirements: requirements)
                    self.syncStateManager.updateAgeOfData(tag: requirements.tag, age: timeFetched)

                    /*
                     Do after saving cache, successfully.
                     This scenario could happen: first fetch -> save new cache -> cache data/empty -> successful first fetch.
                     Even though it would be better to have "successful first fetch" notification before cache data/empty, this scenario is better then if saving cache fails and we get this:
                     first fetch -> successful first fetch -> save new cache -> failed first fetch.
                     We would need to backtrack and that doesn't sound like the best idea. It's best to only say the fetch is successful after it is confirmed successful. Also because
                     */
                    if !hasEverFetchedDataBefore {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.successfulFirstFetch(timeFetched: timeFetched) }
                    } else {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.successfulFetchingFreshCache(timeFetched: timeFetched) }
                    }

                    // Note: Only begin observing after a successful fetch because you could be in the scenario of never fetching before and that state throws an error when calling beginObservingCachedData()
                    // Begin observing cache again. We may be observing for the first time because this is the first fetch, or we begin observing again after we stopped observing before saving.
                    self.beginObservingCachedData(requirements: requirements)
                } catch {
                    if !hasEverFetchedDataBefore {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.errorFirstFetch(error: error) }
                    } else {
                        self.currentStateOfData.changeState(requirements: requirements) { try! $0.failFetchingFreshCache(error) }
                    }
                }

                onComplete()
            }
        case .failure(let fetchError):
            let hasEverFetchedDataBefore = !currentStateOfData.currentState.noCacheExists
            // Note: Make sure that you **do not** beginObservingCachedData() if there is a failure and we have never fetched data successfully before. We cannot begin observing cached data until we know for sure a cache actually exists!
            if !hasEverFetchedDataBefore {
                currentStateOfData.changeState(requirements: requirements) { try! $0.errorFirstFetch(error: fetchError) }
            } else {
                currentStateOfData.changeState(requirements: requirements) { try! $0.failFetchingFreshCache(fetchError) }
            }

            onComplete()
        }
    }
}
