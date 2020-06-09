import Foundation
import RxSwift

internal protocol Repository {
    associatedtype DataSource: RepositoryDataSource

    func refresh(force: Bool) throws -> Single<RefreshResult>
    func refreshIfNoCache() throws -> Single<RefreshResult>
    func observe() -> Observable<CacheState<DataSource.Cache>>
}

/**
 Use in your app: 1 instance per 1 instance of RepositoryDataSource, to observe a RepositoryDataSource.

 1. Initialize an instance of Repository
 2. Set the `dataSource` property with an instance of RepositoryDataSource
 3. Call any of the functions below to sync or observe data.

 Repository is thread safe. Actions called upon for Repository can be performed on any thread.
 */
public class TellerRepository<DS: RepositoryDataSource>: Repository {
    public typealias DataSource = DS

    internal let dataSource: DataSource

    var dataSourceAdapter: AnyRepositoryDataSourceAdapter<DS> {
        return AnyRepositoryDataSourceAdapter(TellerRepositoryDataSourceAdapter(dataSource: dataSource))
    }

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

            if let oldValue = oldValue {
                refreshManager.cancelRefresh(tag: oldValue.tag, requester: self)
            }

            if newValue == nil {
                // When set requirements to nil, we make the repo "dead"
                stopObservingCache()

                currentStateOfData.resetStateToNone()
            }
        }
        didSet {
            if let newValue = requirements {
                // This function requires that self.requirements is set to a value. So, we must call it in didSet
                newRequirementsSet(newValue)
            }
        }
    }

    internal func newRequirementsSet(_ requirements: DataSource.Requirements) {
        // 1. Cancel observing cache so no more reading of cache updates can happen.
        // 2. Cancel refreshing so no fetch can finish.
        // 3. Set curentStateOfData to something so anyone observing does not think they are still observing old requirements (old data).
        // 4. Start everything up again.

        stopObservingCache()

        if syncStateManager.hasEverFetchedData(tag: requirements.tag) {
            currentStateOfData.resetToCacheState(requirements: requirements, lastTimeFetched: syncStateManager.lastTimeFetchedData(tag: requirements.tag)!)
            /**
             Note: It's important that we perform a refresh after we already begin observing a cache state. Else, we may encounter the scenario: cache has not been queried yet, so cache state is first fetch --> refresh begins, first fetch --> cache queried and is not null --> refresh done, done **first fetch** although, it's not really the first fetch. This would result in a crash in the state machine.
             */
            beginObservingCachedData(requirements: requirements)
        } else {
            currentStateOfData.resetToNoCacheState(requirements: requirements)
            // When we set new requirements, we want to fetch for first time if have never been done before. Example: paging data. If we go to a new page we have never gotten before, we want to fetch that data for the first time.
            performAutomaticRefresh(requirements: requirements)
        }
    }

    public init(dataSource: DataSource) {
        self.dataSource = dataSource
        self.syncStateManager = TellerRepositorySyncStateManager()
        self.schedulersProvider = AppSchedulersProvider()
        self.refreshManager = AppRepositoryRefreshManager.shared

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

    private func postInit() {}

    deinit {
        if let requirements = requirements {
            refreshManager.cancelRefresh(tag: requirements.tag, requester: self)
        }

        refreshDisposeBag.dispose()

        currentStateOfData.subject.on(.completed) // By disposing below, `.completed` does not get sent automatically. We must send ourselves. Alert whoever is observing this repository to know the sequence has completed.
        currentStateOfData.subject.dispose()

        stopObservingCache()
    }

    internal func refreshAssert() throws -> DataSource.Requirements {
        guard let requirements = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }

        return requirements
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
        let requirements = try refreshAssert()

        return getRefresh(force: force, requirements: requirements)
    }

    /**
     ### Perform a refresh only if a cache does not yet exist.

     Ideal in these scenarios:
     * App opened for the first time and it cannot operate without a cache.

     - Returns: A Single<RefreshResult> that notifies you asynchronously with how the refresh performed (successful or failed). If a cache exists, RefreshResult.successful will be returned. That way all you need to do is check for `RefreshResult.successful` if a cache exists or not.
     - Throws: TellerError.objectPropertiesNotSet if you did not set `requirements` before calling this function.
     */
    public func refreshIfNoCache() throws -> Single<RefreshResult> {
        let requirements = try refreshAssert()

        guard !syncStateManager.hasEverFetchedData(tag: requirements.tag) else {
            return Single.just(RefreshResult.successful)
        }

        return try refresh(force: false)
    }

    /**
     One of Teller's conveniences is that it performs `refresh(force: false)` calls for you periodically in times such as (1) when new requirements is set, (2) observe() is called, or (3) a cache update is triggered. This is convenient as it helps keep the cache always up-to-date.

     This is where that functionality exists and will get skipped if the developer decides to opt-out of this behavior.
     */
    internal func performAutomaticRefresh(requirements: DataSource.Requirements) {
        guard dataSource.automaticallyRefresh else {
            return
        }

        refreshDisposeBag += getRefresh(force: false, requirements: requirements)
            .subscribeOn(schedulersProvider.background)
            .subscribe()
    }

    internal func needsARefresh(requirements: DataSource.Requirements) -> Bool {
        return !syncStateManager.hasEverFetchedData(tag: requirements.tag) || syncStateManager.isCacheTooOld(tag: requirements.tag, maxAgeOfCache: dataSource.maxAgeOfCache)
    }

    fileprivate func beginObservingCachedData(requirements: DataSource.Requirements) {
        if !syncStateManager.hasEverFetchedData(tag: requirements.tag) {
            fatalError("You cannot begin observing cached data until after data has been successfully fetched at least once")
        }

        /// Running an async operation below is not a problem. Because we are using a thread-safe `self.currentStateOfData`, we can change the state of the cache on any thread at anytime.

        // We need to run some tasks in the background before running on UI. So, switch to background and then to main.
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            self._backgroundTaskBeforeObserveCache(requirements: requirements)

            // We need to (1) get the Observable from the data source, (2) query the DB, and (3) perform actions on the queried DB results all in the main thread. So, we will queue up this work on the main thread.
            // I need to subscribe and observe on the UI thread because popular database solutions such as Realm, Core Data all have a "write on background, read on UI" approach. You cannot read on the background and send the read objects to the UI thread. So, we read on the UI.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.stopObservingCache()

                self.observeCacheDisposeBag += self.dataSourceAdapter.observeCache(requirements: requirements)
                    .subscribeOn(self.schedulersProvider.ui)
                    .observeOn(self.schedulersProvider.ui)
                    .subscribe(onNext: { [weak self, requirements] (cache: DataSource.Cache) in
                        guard let self = self else { return }

                        let needsToFetchFreshCache = self.syncStateManager.isCacheTooOld(tag: requirements.tag, maxAgeOfCache: self.dataSource.maxAgeOfCache)

                        if self.dataSourceAdapter.isCacheEmpty(cache: cache, requirements: requirements) {
                            self.currentStateOfData.changeState(requirements: requirements) { try! $0.cacheIsEmpty() }
                        } else {
                            self.currentStateOfData.changeState(requirements: requirements) { try! $0.cachedData(cache) }
                        }

                        if needsToFetchFreshCache {
                            self.performAutomaticRefresh(requirements: requirements)
                        }
                    })
            }
        }
    }

    /**
     ### Observe changes to the state of data.

     **Note**
     * The state of the Observable returned from this function is maintained by the Repository. When the Repository `deinit` is called, all observers will be disposed.
     * When you subscribe to the returned `Observable`, you will receive a result immediately with the current state of the data when you subscribe (even if there is "no state").

     - Returns: A RxSwift Observable<CacheState<Cache>> instance that gets notified when the state of the cached data changes.
     */
    public func observe() -> Observable<CacheState<DataSource.Cache>> {
        if let requirements = requirements {
            // Trigger a refresh to help keep data up-to-date.
            performAutomaticRefresh(requirements: requirements)
        }

        return currentStateOfData.subject
            .filter { !$0.isNone }
    }

    private func stopObservingCache() {
        observeCacheDisposeBag.dispose()
        observeCacheDisposeBag = CompositeDisposable()
    }

    private func getRefresh(force: Bool, requirements: DataSource.Requirements) -> Single<RefreshResult> {
        let runBeforeRefresh: Completable = Completable.create { [weak self] (observer) -> Disposable in
            self?._backgroundTaskBeforeRefresh(forceRefresh: force, requirements: requirements)

            observer(.completed)

            return Disposables.create()
        }.subscribeOn(schedulersProvider.background)

        if force || needsARefresh(requirements: requirements) {
            return runBeforeRefresh.andThen(refreshManager.getRefresh(task: dataSourceAdapter.fetchFreshCache(requirements: requirements), tag: requirements.tag, requester: self))
        } else {
            return Single.just(.skipped(reason: .dataNotTooOld))
        }
    }

    /**
     Always called on background thread.
     */
    internal func _backgroundTaskBeforeObserveCache(requirements: DataSource.Requirements) {}

    /**
     Always called on background thread.
     */
    internal func _backgroundTaskBeforeRefresh(forceRefresh: Bool, requirements: DataSource.Requirements) {}

    class TellerRepositoryDataSourceAdapter: RepositoryDataSourceAdapter {
        typealias DataSource = DS
        typealias ObserveCacheState = DS.Cache

        let dataSource: DS

        init(dataSource: DS) {
            self.dataSource = dataSource
        }

        func fetchFreshCache(requirements: DS.Requirements) -> Single<FetchResponse<DS.FetchResult, DS.FetchError>> {
            return dataSource.fetchFreshCache(requirements: requirements)
        }

        func saveCache(newCache: DS.FetchResult, requirements: DS.Requirements) throws {
            try dataSource.saveCache(newCache, requirements: requirements)
        }

        func isCacheEmpty(cache: DS.Cache, requirements: DS.Requirements) -> Bool {
            return dataSource.isCacheEmpty(cache, requirements: requirements)
        }

        func observeCache(requirements: DS.Requirements) -> Observable<ObserveCacheState> {
            return dataSource.observeCache(requirements: requirements)
        }
    }
}

extension TellerRepository: RepositoryRefreshManagerDelegate {
    // called on background thread
    internal func refreshBegin(tag: RepositoryRequirements.Tag) {
        // User may have changed requirements
        guard let requirements = self.requirements else { return }
        guard requirements.tag == tag else { return }

        let hasEverFetchedDataBefore = currentStateOfData.currentState.cacheExists

        if !hasEverFetchedDataBefore {
            currentStateOfData.changeState(requirements: requirements) { try! $0.firstFetch() }
        } else {
            currentStateOfData.changeState(requirements: requirements) { try! $0.fetchingFreshCache() }
        }
    }

    // called on background thread
    internal func refreshSuccessful<FetchResponseData, ErrorType>(_ response: FetchResponse<FetchResponseData, ErrorType>, tag: RepositoryRequirements.Tag) {
        // User may have changed requirements
        guard let requirements = self.requirements else { return }
        guard requirements.tag == tag else { return }

        switch response {
        case .success(let success):
            let newCache: DataSource.FetchResult = success as! DataSource.FetchResult // swiftlint:disable:this force_cast

            let timeFetched = Date()
            let hasEverFetchedDataBefore = currentStateOfData.currentState.cacheExists

            do {
                // We need to stop observing cache before saving. saveData() will trigger an onNext() from the cache observable in the dataSource because data is being saved and Observables are supposed to trigger updates like that. The problem is that when we are observing cache in the repository, we trigger a refresh depending on the age of the cache. But as you can see from comments below, we don't want to update the age of the cache until after the save is successful. So, we need to have control over when the cache is observed. We want to read the cache after it is successfully saved and then after we update the state machine and age of cache. Then, the state machine will be in the correct state and the age of cache will not trigger a refresh update automatically.
                stopObservingCache()

                try dataSourceAdapter.saveCache(newCache: newCache, requirements: requirements)
                syncStateManager.updateAgeOfData(tag: requirements.tag, age: timeFetched)

                /*
                 Do after saving cache, successfully.
                 This scenario could happen: first fetch -> save new cache -> cache data/empty -> successful first fetch.
                 Even though it would be better to have "successful first fetch" notification before cache data/empty, this scenario is better then if saving cache fails and we get this:
                 first fetch -> successful first fetch -> save new cache -> failed first fetch.
                 We would need to backtrack and that doesn't sound like the best idea. It's best to only say the fetch is successful after it is confirmed successful. Also because
                 */
                if !hasEverFetchedDataBefore {
                    currentStateOfData.changeState(requirements: requirements) { try! $0.successfulFirstFetch(timeFetched: timeFetched) }
                } else {
                    currentStateOfData.changeState(requirements: requirements) { try! $0.successfulFetchingFreshCache(timeFetched: timeFetched) }
                }

                // Note: Only begin observing after a successful fetch because you could be in the scenario of never fetching before and that state throws an error when calling beginObservingCachedData()
                // Begin observing cache again. We may be observing for the first time because this is the first fetch, or we begin observing again after we stopped observing before saving.
                beginObservingCachedData(requirements: requirements)
            } catch {
                if !hasEverFetchedDataBefore {
                    currentStateOfData.changeState(requirements: requirements) { try! $0.errorFirstFetch(error: error) }
                } else {
                    currentStateOfData.changeState(requirements: requirements) { try! $0.failFetchingFreshCache(error) }
                }
            }
        case .failure(let fetchError):
            let hasEverFetchedDataBefore = currentStateOfData.currentState.cacheExists
            // Note: Make sure that you **do not** beginObservingCachedData() if there is a failure and we have never fetched data successfully before. We cannot begin observing cached data until we know for sure a cache actually exists!
            if !hasEverFetchedDataBefore {
                currentStateOfData.changeState(requirements: requirements) { try! $0.errorFirstFetch(error: fetchError) }
            } else {
                currentStateOfData.changeState(requirements: requirements) { try! $0.failFetchingFreshCache(fetchError) }
            }
        }
    }
}
