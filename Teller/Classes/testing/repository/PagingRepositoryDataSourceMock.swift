import Foundation
import RxSwift

/**
 Mock Teller's `RepositoryDataSource`. Meant to be used with unit tests where you use `RepositoryDataSource`.

 Note: Unit tests will not fully test your implementation of Teller in your app. Create a mix of unit and integration tests in order to get good test coverage.
 */
public class PagingRepositoryDataSourceMock<PagingCache: Any, Requirements: RepositoryRequirements, PagingRequirements: PagingRepositoryRequirements, PagingFetchResult: Any, FetchError: Error, NextPageRequirements: Any>: PagingRepositoryDataSource {
    public typealias PagingRequirements = PagingRequirements
    public typealias NextPageRequirements = NextPageRequirements
    public typealias PagingCache = PagingCache
    public typealias PagingFetchResult = PagingFetchResult

    public typealias FetchResult = PagedFetchResponse<PagingFetchResult, NextPageRequirements>
    public typealias Cache = PagedCache<PagingCache>

    public var mockCalled: Bool = false // if *any* interactions done on mock. Sets/gets or methods called.

    public var getNextPagePagingRequirementsCallsCount = 0
    public var getNextPagePagingRequirementsCalled: Bool {
        return getNextPagePagingRequirementsCallsCount > 0
    }

    public var getNextPagePagingRequirementsInvocations: [(PagingRequirements, NextPageRequirements?)] = []
    public var getNextPagePagingRequirementsClosure: ((PagingRequirements, NextPageRequirements?) -> PagingRequirements)?
    public func getNextPagePagingRequirements(currentPagingRequirements: PagingRequirements, nextPageRequirements: NextPageRequirements?) -> PagingRequirements {
        mockCalled = true
        getNextPagePagingRequirementsCallsCount += 1
        getNextPagePagingRequirementsInvocations.append((currentPagingRequirements, nextPageRequirements))
        return getNextPagePagingRequirementsClosure!(currentPagingRequirements, nextPageRequirements)
    }

    public var persistOnlyFirstPageCallsCount = 0
    public var persistOnlyFirstPageCalled: Bool {
        return persistOnlyFirstPageCallsCount > 0
    }

    public var persistOnlyFirstPageInvocations: [Requirements] = []
    public var persistOnlyFirstPageClosure: ((Requirements) -> Void)?
    public func persistOnlyFirstPage(requirements: Requirements) {
        mockCalled = true
        persistOnlyFirstPageCallsCount += 1
        persistOnlyFirstPageInvocations.append(requirements)
        persistOnlyFirstPageClosure?(requirements)
    }

    public var deleteCacheCallsCount = 0
    public var deleteCacheCalled: Bool {
        return deleteCacheCallsCount > 0
    }

    public var deleteCacheInvocations: [Requirements] = []
    public var deleteCacheClosure: ((Requirements) -> Void)?
    public func deleteCache(_ requirements: Requirements) {
        mockCalled = true
        deleteCacheCallsCount += 1
        deleteCacheInvocations.append(requirements)
        deleteCacheClosure?(requirements)
    }

    public var automaticallyRefreshCallsCount = 0
    public var automaticallyRefreshCalled: Bool {
        return automaticallyRefreshCallsCount > 0
    }

    public var automaticallyRefreshClosure: (() -> Bool)?
    public var automaticallyRefresh: Bool {
        mockCalled = true
        automaticallyRefreshCallsCount += 1
        // return default value, just like the real RepositoryDataSource does.
        return automaticallyRefreshClosure?() ?? true
    }

    public var maxAgeOfCacheCallsCount = 0
    public var maxAgeOfCacheCalled: Bool {
        return maxAgeOfCacheCallsCount > 0
    }

    public var maxAgeOfCacheClosure: (() -> Period)?
    public var maxAgeOfCache: Period {
        mockCalled = true
        maxAgeOfCacheCallsCount += 1
        return maxAgeOfCacheClosure!()
    }

    public var fetchFreshCacheCallsCount = 0
    public var fetchFreshCacheCalled: Bool {
        return fetchFreshCacheCallsCount > 0
    }

    public var fetchFreshCacheInvocations: [(Requirements, PagingRequirements)] = []
    public var fetchFreshCacheClosure: ((Requirements, PagingRequirements) -> Single<FetchResponse<FetchResult, FetchError>>)?
    public func fetchFreshCache(requirements: Requirements, pagingRequirements: PagingRequirements) -> Single<FetchResponse<FetchResult, FetchError>> {
        mockCalled = true
        fetchFreshCacheCallsCount += 1
        fetchFreshCacheInvocations.append((requirements, pagingRequirements))
        return fetchFreshCacheClosure!(requirements, pagingRequirements)
    }

    public var saveCacheCallsCount = 0
    public var saveCacheCalled: Bool {
        return saveCacheCallsCount > 0
    }

    public var saveCacheInvocations: [(PagingFetchResult, Requirements, PagingRequirements)] = []
    public var saveCacheClosure: ((PagingFetchResult, Requirements, PagingRequirements) throws -> Void)?
    public func saveCache(_ cache: PagingFetchResult, requirements: Requirements, pagingRequirements: PagingRequirements) throws {
        mockCalled = true
        saveCacheCallsCount += 1
        saveCacheInvocations.append((cache, requirements, pagingRequirements))
        try saveCacheClosure?(cache, requirements, pagingRequirements)
    }

    public var observeCacheCallsCount = 0
    public var observeCacheCalled: Bool {
        return observeCacheCallsCount > 0
    }

    public var observeCacheInvocations: [(Requirements, PagingRequirements)] = []
    public var observeCacheClosure: ((Requirements, PagingRequirements) -> Observable<PagingCache>)?
    public func observeCache(requirements: Requirements, pagingRequirements: PagingRequirements) -> Observable<PagingCache> {
        mockCalled = true
        observeCacheCallsCount += 1
        observeCacheInvocations.append((requirements, pagingRequirements))
        return observeCacheClosure!(requirements, pagingRequirements)
    }

    public var isCacheEmptyCallsCount = 0
    public var isCacheEmptyCalled: Bool {
        return isCacheEmptyCallsCount > 0
    }

    public var isCacheEmptyInvocations: [(PagingCache, Requirements, PagingRequirements)] = []
    public var isCacheEmptyClosure: ((PagingCache, Requirements, PagingRequirements) -> Bool)?
    public func isCacheEmpty(_ cache: PagingCache, requirements: Requirements, pagingRequirements: PagingRequirements) -> Bool {
        mockCalled = true
        isCacheEmptyCallsCount += 1
        isCacheEmptyInvocations.append((cache, requirements, pagingRequirements))
        return isCacheEmptyClosure!(cache, requirements, pagingRequirements)
    }
}

extension PagingRepositoryDataSourceMock {
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
