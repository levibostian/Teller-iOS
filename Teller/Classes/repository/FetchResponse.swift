import Foundation

/**
 Result of a RepositoryDataSource.fetchFreshCache call. It's an object that is generic enough that Repository can understand it.
 */
public typealias FetchResponse<DataType: Any, ErrorType: Error> = Result<DataType, ErrorType>
