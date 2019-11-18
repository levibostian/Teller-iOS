import Foundation

/**
 Result of a OnlineRepositoryDataSource.fetchFreshData call. It's an object that is generic enough that OnlineRepository can understand it.
 */
public typealias FetchResponse<DataType: Any> = Result<DataType, Swift.Error>
