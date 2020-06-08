import Foundation
import RxSwift

/**
 Mock Teller's `RepositoryDataSource`. Meant to be used with unit tests where you use `RepositoryDataSource`.

 Note: Unit tests will not fully test your implementation of Teller in your app. Create a mix of unit and integration tests in order to get good test coverage.
 */
public class RepositoryDataSourceMock<Cache: Any, Requirements: RepositoryRequirements, FetchResult: Any, FetchError: Error>: RepositoryDataSource {
    public typealias Cache = Cache
    public typealias Requirements = Requirements
    public typealias FetchResult = FetchResult
    public typealias FetchError = FetchError

    public var mockCalled: Bool = false // if *any* interactions done on mock. Sets/gets or methods called.

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

    public var fetchFreshCacheInvocations: [Requirements] = []
    public var fetchFreshCacheClosure: ((Requirements) -> Single<FetchResponse<FetchResult, FetchError>>)?
    public func fetchFreshCache(requirements: Requirements) -> Single<FetchResponse<FetchResult, FetchError>> {
        mockCalled = true
        fetchFreshCacheCallsCount += 1
        fetchFreshCacheInvocations.append(requirements)
        return fetchFreshCacheClosure!(requirements)
    }

    public var saveCacheCallsCount = 0
    public var saveCacheCalled: Bool {
        return saveCacheCallsCount > 0
    }

    public var saveCacheInvocations: [(FetchResult, Requirements)] = []
    public var saveCacheClosure: ((FetchResult, Requirements) throws -> Void)?
    public func saveCache(_ cache: FetchResult, requirements: Requirements) throws {
        mockCalled = true
        saveCacheCallsCount += 1
        saveCacheInvocations.append((cache, requirements))
        try saveCacheClosure?(cache, requirements)
    }

    public var observeCacheCallsCount = 0
    public var observeCacheCalled: Bool {
        return observeCacheCallsCount > 0
    }

    public var observeCacheInvocations: [Requirements] = []
    public var observeCacheClosure: ((Requirements) -> Observable<Cache>)?
    public func observeCache(requirements: Requirements) -> Observable<Cache> {
        mockCalled = true
        observeCacheCallsCount += 1
        observeCacheInvocations.append(requirements)
        return observeCacheClosure!(requirements)
    }

    public var isCacheEmptyCallsCount = 0
    public var isCacheEmptyCalled: Bool {
        return isCacheEmptyCallsCount > 0
    }

    public var isCacheEmptyInvocations: [(Cache, Requirements)] = []
    public var isCacheEmptyClosure: ((Cache, Requirements) -> Bool)?
    public func isCacheEmpty(_ cache: Cache, requirements: Requirements) -> Bool {
        mockCalled = true
        isCacheEmptyCallsCount += 1
        isCacheEmptyInvocations.append((cache, requirements))
        return isCacheEmptyClosure!(cache, requirements)
    }
}
