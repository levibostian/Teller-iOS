import Foundation
import RxSwift

/**
 `TellerRepository` meant specifically for paging pages of cached data.

 Notes about this class:
 # We always want to perform a refresh. Do not check the age of the cache with paging.

 Why? When you call this function, you are either:
 1. Querying the cache after opening the screen of the app for the first time. When we are paging the cache, we are only displaying the first page of the cache and we delete all of the rest. Because we deleted the old data, we need to always perform a refresh. Two bad scenarios can happen if you do not refresh the first page. 1. the paging repository generates a cache state saying there is no more pages of cache available when that might not be true or 2. the user scrolls, we fetch the 2nd page which now means the 2nd page is up-to-date but the first page is always out of date.
 2. For all page numbers 2+, we always fetch because the way pagination works is to delete all of the cache except the first page of the cache so if you set the page requirements, that means the user has scrolled. Because they have scrolled, we need to fetch the next page and put into the cache to show.
 */
public class TellerPagingRepository<DS: PagingRepositoryDataSource>: TellerRepository<DS> {
    /**
     * Used to hold the value of [pagingRequirements], without actions. [pagingRequirements] is meant to trigger actions when set. This is the backing property for it.
     */
    private let _pagingRequirements: Atomic<DS.PagingRequirements>
    private let firstPageRequirements: DS.PagingRequirements
    internal let pagingDataSource: DS
    // nil when (1) a successful fetch has never happened before, (2) when there are no more pages to load.
    internal var nextPageRequirements: DS.NextPageRequirements?
    public private(set) var areMorePagesAvailable: Bool = false

    override var dataSourceAdapter: AnyRepositoryDataSourceAdapter<DS> {
        return AnyRepositoryDataSourceAdapter(PagingRepositoryDataSourceAdapter(dataSource: dataSource, repository: self))
    }

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

    override internal func newRequirementsSet(_ requirements: DataSource.Requirements) {
        super.newRequirementsSet(requirements)

        // Re-set the paging requirements to trigger the set function
        let currentPagingRequirements = pagingRequirements
        pagingRequirements = currentPagingRequirements
    }

    /**
     * Requirements specifically to determine what page of data we are requesting.
     *
     * We always want to perform an automatic refresh. See class documentation to learn why.
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

    /**
     Goes to the next page. Request will only succeed if a successful fetch has happened and there are more pages to load.
     */
    public func goToNextPage() {
        guard areMorePagesAvailable else {
            return // Ignore request. This is better then throwing an error because when the app opens up and loads cache, you can immediately scroll to the end of the list and call this before a fetch response comes in. You shouldn't need to handle that scenario.
        }

        pagingRequirements = pagingDataSource.getNextPagePagingRequirements(currentPagingRequirements: pagingRequirements, nextPageRequirements: nextPageRequirements)
    }

    private var isFirstPage: Bool {
        return pagingRequirements == firstPageRequirements
    }

    /**
     * We always want to perform a refresh. See class documentation to learn why.
     */
    override internal func needsARefresh(requirements: DataSource.Requirements) -> Bool {
        return true
    }

    override internal func _backgroundTaskBeforeRefresh(forceRefresh: Bool, requirements: DataSource.Requirements) {
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

    override internal func _backgroundTaskBeforeObserveCache(requirements: DataSource.Requirements) {
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

    class PagingRepositoryDataSourceAdapter: RepositoryDataSourceAdapter {
        typealias DataSource = DS

        let dataSource: DS
        let repository: TellerPagingRepository

        init(dataSource: DS, repository: TellerPagingRepository) {
            self.dataSource = dataSource
            self.repository = repository
        }

        func fetchFreshCache(requirements: DS.Requirements) -> Single<FetchResponse<DS.FetchResult, DS.FetchError>> {
            return dataSource.fetchFreshCache(requirements: requirements, pagingRequirements: repository.pagingRequirements)
        }

        func saveCache(newCache: DS.FetchResult, requirements: DS.Requirements) throws {
            // If this new cache is the first page of cache, we want to completely replace the cache. So, Teller will ask you to delete the old cache first and then you will insert the new cache.
            if repository.isFirstPage {
                dataSource.deleteCache(requirements)
            }

            repository.nextPageRequirements = newCache.nextPageRequirements
            repository.areMorePagesAvailable = newCache.areMorePages

            try dataSource.saveCache(newCache.fetchResponse, requirements: requirements, pagingRequirements: repository.pagingRequirements)
        }

        func isCacheEmpty(cache: DS.Cache, requirements: DS.Requirements) -> Bool {
            return dataSource.isCacheEmpty(cache.cache, requirements: requirements, pagingRequirements: repository.pagingRequirements)
        }

        func observeCache(requirements: DS.Requirements) -> Observable<DS.Cache> {
            return dataSource.observeCache(requirements: requirements, pagingRequirements: repository.pagingRequirements)
                .map { (pagingCache) -> DS.Cache in
                    PagedCache(areMorePages: self.repository.areMorePagesAvailable, cache: pagingCache)
                }
        }
    }
}
