import Foundation
import RxSwift

public protocol PagingRepositoryRequirements: Equatable {}

public protocol PagingRepositoryDataSource: RepositoryDataSource {
    associatedtype PagingRequirements: PagingRepositoryRequirements

    /**
     * Called by the repository to ask you to delete the cached data that is beyond the first page of the cache. If you, for example, have 150 items of data saved to the device as a cache (3 pages of 50 items per page), keep the first 50 items (because 50 is the page size) and delete the last 100 items.
     *
     * This is done to prevent the scenario happening where the app opens up in the future, queries all of the old cached data, the user scrolls to the end of the list, and the repository is asked to go to the next page but if the cache size is larger then the page size, then the next page will not be accurate. If your page size is 50 but you scroll 150 items of an old cache, you are telling the repository to go to page 2 with the last cache item being at position 150 when that's actually the end of page 3 because the page size is 50.
     *
     * **Called on a background thread**
     */
    func persistOnlyFirstPage(requirements: Requirements)

    func fetchFreshCache(requirements: Requirements, pagingRequirements: PagingRequirements) -> Single<FetchResponse<FetchResult, FetchError>>

    /**
     * Save the new cache [cache] to whatever storage method [OnlineRepository] chooses.
     *
     * **Called on a background thread.**
     */
    func saveCache(_ cache: FetchResult, requirements: Requirements, pagingRequirements: PagingRequirements) throws

    /**
     * Get existing cache saved on the device if it exists. If no cache exists, return an empty response set in the Observable and return true in [isCacheEmpty]. **Do not** return nil or an Observable with nil as a value as this will cause an exception.
     *
     * This function is only called after cache has been fetched successfully from [fetchFreshCache].
     *
     * **Called on main UI thread.**
     */
    func observeCache(requirements: Requirements, pagingRequirements: PagingRequirements) -> Observable<Cache>

    /**
     * Used to determine if cache is empty or not.
     *
     * **Called on main UI thread.**
     */
    func isCacheEmpty(_ cache: Cache, requirements: Requirements, pagingRequirements: PagingRequirements) -> Bool
}

/**
 Override the functions from `RepositoryDataSource` so you don't have to. You should only need to implement the paging equivalents from the protocol.

 Fatal errors are called here because the only one calling these functions is a  `TellerPagingRepository` anyway.
 */
extension PagingRepositoryDataSource {
    public func fetchFreshCache(requirements: Requirements) -> Single<FetchResponse<FetchResult, FetchError>> {
        fatalError("Not correct function. Call the paging version instead.")
    }

    public func saveCache(_ cache: FetchResult, requirements: Requirements) throws {
        fatalError("Not correct function. Call the paging version instead")
    }

    public func observeCache(requirements: Requirements) -> Observable<Cache> {
        fatalError("Not correct function. Call the paging version instead")
    }

    public func isCacheEmpty(_ cache: Cache, requirements: Requirements) -> Bool {
        fatalError("Not correct function. Call the paging version instead")
    }
}
