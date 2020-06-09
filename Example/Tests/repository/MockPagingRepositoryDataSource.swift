import Foundation
import RxSwift
@testable import Teller

internal class MockPagingRepositoryDataSource: PagingRepositoryDataSource {
    typealias PagingRequirements = MockPagingRequirements
    typealias PagingCache = String
    typealias NextPageRequirements = Void
    typealias Requirements = MockRequirements
    typealias PagingFetchResult = String
    typealias FetchError = Error

    var deleteCacheCount = 0
    var deleteCacheThen: (() -> Void)?

    var persistOnlyFirstPageCount = 0
    var persistOnlyFirstPageThen: (() -> Void)?

    var fetchFreshDataCount = 0
    var fetchFreshDataRequirements: MockRequirements?
    var saveDataCount = 0
    var saveDataFetchedData: String?
    var saveDataThen: ((String) throws -> Void)?
    var observeCachedDataCount = 0
    var observeCacheDataThenAnswer: ((MockRequirements) -> Observable<String>)?
    var isDataEmptyCount = 0

    var maxAgeOfCache: Period
    var fakeData: FakeData

    var automaticallyRefresh: Bool {
        return fakeData.automaticallyRefresh
    }

    init(fakeData: FakeData, maxAgeOfCache: Period) {
        self.fakeData = fakeData
        self.maxAgeOfCache = maxAgeOfCache
    }

    func getNextPagePagingRequirements(currentPagingRequirements: MockPagingRequirements, nextPageRequirements: Void?) -> MockPagingRequirements {
        return MockPagingRequirements(pageNumber: currentPagingRequirements.pagingNumber)
    }

    func deleteCache(_ requirements: MockRequirements) {
        deleteCacheCount += 1
        deleteCacheThen?()
    }

    func persistOnlyFirstPage(requirements: MockRequirements) {
        persistOnlyFirstPageCount += 1
        persistOnlyFirstPageThen?()
    }

    func fetchFreshCache(requirements: MockRequirements, pagingRequirements: MockPagingRequirements) -> Single<FetchResponse<PagedFetchResponse<String, Void>, Error>> {
        fetchFreshDataCount += 1
        fetchFreshDataRequirements = requirements
        return fakeData.fetchFreshData
    }

    func saveCache(_ cache: String, requirements: MockRequirements, pagingRequirements: MockPagingRequirements) throws {
        saveDataCount += 1
        saveDataFetchedData = cache
        try saveDataThen?(cache)
    }

    func observeCache(requirements: MockRequirements, pagingRequirements: MockPagingRequirements) -> Observable<String> {
        observeCachedDataCount += 1
        return observeCacheDataThenAnswer?(requirements) ?? fakeData.observeCachedData
    }

    func isCacheEmpty(_ cache: String, requirements: MockRequirements, pagingRequirements: MockPagingRequirements) -> Bool {
        isDataEmptyCount += 1
        return fakeData.isDataEmpty
    }

    struct FakeData {
        var automaticallyRefresh: Bool
        var isDataEmpty: Bool
        var observeCachedData: Observable<String>
        var fetchFreshData: Single<FetchResponse<PagedFetchResponse<String, Void>, Error>>
    }

    struct MockRequirements: RepositoryRequirements, Equatable {
        var tag: RepositoryRequirements.Tag = "MockRequirements"

        let randomString: String?

        init(randomString: String?) {
            self.randomString = randomString
        }

        static func == (lhs: MockRequirements, rhs: MockRequirements) -> Bool {
            return lhs.tag == rhs.tag && lhs.randomString == rhs.randomString
        }
    }

    struct MockPagingRequirements: PagingRepositoryRequirements, Equatable {
        let pagingNumber: Int

        init(pageNumber: Int = 1) {
            self.pagingNumber = pageNumber
        }
    }
}
