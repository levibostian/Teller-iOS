import Foundation
import RxSwift

/**
 `TellerRepository` meant specifically for paging pages of cached data.
 */
public class TellerPagingRepository<DS: PagingRepositoryDataSource>: TellerRepository<DS> {
    /**
     * Used to hold the value of [pagingRequirements], without actions. [pagingRequirements] is meant to trigger actions when set. This is the backing property for it.
     */
    private let _pagingRequirements: Atomic<DS.PagingRequirements>
    private let firstPageRequirements: DS.PagingRequirements
    internal let pagingDataSource: DS

    public init(dataSource: DS, firstPageRequirements: DS.PagingRequirements) {
        self.pagingDataSource = dataSource
        self.firstPageRequirements = firstPageRequirements
        self._pagingRequirements = Atomic(value: firstPageRequirements)

        super.init(dataSource: dataSource)
    }

    // init designed for testing purposes. Pass in mocked `syncStateManager` if you wish.
    // The Repository is designed to *not* perform any behavior until parameters have been set sometime in the future. **Do not** trigger any refresh, observe, etc behavior in init.
    internal init(firstPageRequirements: DS.PagingRequirements, dataSource: DS, syncStateManager: RepositorySyncStateManager, schedulersProvider: SchedulersProvider, refreshManager: RepositoryRefreshManager) {
        self.pagingDataSource = dataSource
        self.firstPageRequirements = firstPageRequirements
        self._pagingRequirements = Atomic(value: firstPageRequirements)

        super.init(dataSource: dataSource, syncStateManager: syncStateManager, schedulersProvider: schedulersProvider, refreshManager: refreshManager)
    }

    internal override func newRequirementsSet(_ requirements: DataSource.Requirements) {
        super.newRequirementsSet(requirements)

        // Re-set the paging requirements to trigger the set function
        let currentPagingRequirements = pagingRequirements
        pagingRequirements = currentPagingRequirements
    }

    /**
     * Requirements specifically to determine what page of data we are requesting.
     *
     * *Note: When the paging requirements are set, a fetch will be executed no matter what. No check if data too old. Checking if a cache is old is only done by Teller for the first page of the cache. All future pages are fetched because the way pagination works is to delete all of the cache except the first page of the cache so if you set the page requirements, that means the user has scrolled. Because they have scrolled, we need to fetch the next page and put into the cache to show.*
     */
    public var pagingRequirements: DataSource.PagingRequirements {
        set {
            _pagingRequirements.set(newValue)

            if let requirements = self.requirements {
                // Setting new paging requirements is only called when setting the paging requirements as you scroll. The first page will not be executed so that avoids calling refresh even when the first page of data is not too old according to teller.
                performAutomaticRefresh(requirements: requirements)
            }
        }
        get {
            return _pagingRequirements.get
        }
    }

    private var isFirstPage: Bool {
        return pagingRequirements == firstPageRequirements
    }

    internal override func _fetchFreshCache(requirements: DataSource.Requirements) -> Single<FetchResponse<DataSource.FetchResult, DataSource.FetchError>> {
        return pagingDataSource.fetchFreshCache(requirements: requirements, pagingRequirements: pagingRequirements)
    }

    /**
     * Checking if a cache is old is only done by Teller for the first page of the cache. All future pages are fetched because the way pagination works is to delete all of the cache except the first page of the cache so if you set the page requirements, that means the user has scrolled. Because they have scrolled, we need to fetch the next page and put into the cache to show.*
     */
    internal override func needsARefresh(requirements: DataSource.Requirements) -> Bool {
        if !isFirstPage {
            return true
        } else {
            return super.needsARefresh(requirements: requirements)
        }
    }

    internal override func _backgroundTaskBeforeRefresh(forceRefresh: Bool, requirements: DataSource.Requirements) {
        /**
         * If a refresh needs to happen you are:
         * 1. Performing a *force* refresh by doing a pull-to-refresh in the UI in which case you want to get the first page anyway.
         * 2. Doing a background refresh. In this scenario, you only care about saving the new first page anyway. We know you are doing a background fetch if set to first page.

         * If paging requirements is set to not the first page, the user has scrolled and we don't want to change anything.
         *
         * For these reasons, we are going to reset the paging requirements for you and also delete old cache data.
         */
        if forceRefresh || isFirstPage { // if we are performing
            _pagingRequirements.set(firstPageRequirements)
            pagingDataSource.persistOnlyFirstPage(requirements: requirements)
        }
    }

    internal override func _isCacheEmpty(cache: DataSource.Cache, requirements: DS.Requirements) -> Bool {
        return pagingDataSource.isCacheEmpty(cache, requirements: requirements, pagingRequirements: pagingRequirements)
    }

    internal override func _backgroundTaskBeforeObserveCache(requirements: DataSource.Requirements) {
        /**
         * If you are observing the cache, you are beginning to read the cache. You have not yet shown the cache in the UI yet. Because of that, we need to delete the old cache beyond the first page so that the page number aligns with how much data is in the cache.
         * But, deleting data needs to be asynchronous in case you need to run it in the UI thread or background thread. You choose. So, delete the old cache and then begin observing.
         *
         * Only delete if paging requirements is set to initial. If the paging requirements has changed, it means the user has scrolled in the app and you don't want to delete that data while they are viewing it.
         */
        if isFirstPage {
            pagingDataSource.persistOnlyFirstPage(requirements: requirements)
        }
    }

    internal override func _observeCache(requirements: DataSource.Requirements) -> Observable<DataSource.Cache> {
        return pagingDataSource.observeCache(requirements: requirements, pagingRequirements: pagingRequirements)
    }

    internal override func _saveCache(newCache: DataSource.FetchResult, requirements: DS.Requirements) throws {
        try pagingDataSource.saveCache(newCache, requirements: requirements, pagingRequirements: pagingRequirements)
    }
}
