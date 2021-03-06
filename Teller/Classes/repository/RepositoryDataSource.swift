import Foundation
import RxSwift

public protocol RepositoryRequirements {
    typealias Tag = String

    var tag: Tag { get }
}

public protocol RepositoryDataSource {
    associatedtype Cache: Any
    associatedtype Requirements: RepositoryRequirements
    associatedtype FetchResult: Any
    associatedtype FetchError: Error

    var maxAgeOfCache: Period { get }

    var automaticallyRefresh: Bool { get }

    /**
     Repository does what it needs in order to fetch fresh cacheData. Probably call network API.

     Feel free to call this function yourself anytime that you want to perform an API call *without* affecting the `Repository`.

     **Called on a background thread.**
     */
    func fetchFreshCache(requirements: Requirements) -> Single<FetchResponse<FetchResult, FetchError>>

    /**
     * Save the cacheData to whatever storage method Repository chooses.
     *
     * It is up to you to call [saveData] when you have new cacheData to save. A good place to do this is in a ViewModel.
     *
     * *Note:* It is up to you to run this function from a background thread. This is not done by default for you.
     *
     * **Called on a background thread.**
     */
    func saveCache(_ cache: FetchResult, requirements: Requirements) throws

    /**
     Get existing cached cacheData saved to the device if it exists. If no data exists, return an empty data set. **Do not** return nil or an Observable with nil as a value.

     This function will be always executed on a background thread.

     This function is only called after data has been fetched successfully. Assume that data is empty (no cache data) or there is cache data.

     **Called on main UI thread.**
     */
    func observeCache(requirements: Requirements) -> Observable<Cache>

    /**
     * DataType determines if cacheData is empty or not. Because cacheData can be of `Any` type, the DataType must determine when cacheData is empty or not.

     **Called on main UI thread.**
     */
    func isCacheEmpty(_ cache: Cache, requirements: Requirements) -> Bool
}

public extension RepositoryDataSource {
    /**
     Enable Teller automatically performing refresh calls on your behalf when the Repository is observed or new requirements are set.

     If `false` is returned, it's the responsibility of the developer to manually call `Repository.refresh()` to keep the cache up-to-date.

     Default is `true`.
     */
    var automaticallyRefresh: Bool {
        return true
    }
}
