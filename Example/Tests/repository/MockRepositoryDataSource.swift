import Foundation
import RxSwift
@testable import Teller

internal class MockRepositoryDataSource: RepositoryDataSource {
    typealias Cache = String
    typealias Requirements = MockRequirements
    typealias FetchResult = String
    typealias FetchError = Error

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

    func fetchFreshCache(requirements: MockRequirements) -> Single<FetchResponse<String, FetchError>> {
        fetchFreshDataCount += 1
        fetchFreshDataRequirements = requirements
        return fakeData.fetchFreshData
    }

    func saveCache(_ fetchedData: String, requirements: MockRepositoryDataSource.MockRequirements) throws {
        saveDataCount += 1
        saveDataFetchedData = fetchedData
        try saveDataThen?(fetchedData)
    }

    func observeCache(requirements: MockRequirements) -> Observable<String> {
        observeCachedDataCount += 1
        return observeCacheDataThenAnswer?(requirements) ?? fakeData.observeCachedData
    }

    func isCacheEmpty(_ cache: String, requirements: MockRepositoryDataSource.MockRequirements) -> Bool {
        isDataEmptyCount += 1
        return fakeData.isDataEmpty
    }

    struct FakeData {
        var automaticallyRefresh: Bool
        var isDataEmpty: Bool
        var observeCachedData: Observable<String>
        var fetchFreshData: Single<FetchResponse<String, Error>>
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
}
