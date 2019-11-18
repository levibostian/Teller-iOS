import Foundation
import RxSwift
@testable import Teller

internal class MockOnlineRepositoryDataSource: OnlineRepositoryDataSource {
    typealias Cache = String
    typealias GetDataRequirements = MockGetDataRequirements
    typealias FetchResult = String

    var fetchFreshDataCount = 0
    var fetchFreshDataRequirements: MockGetDataRequirements?
    var saveDataCount = 0
    var saveDataFetchedData: String?
    var saveDataThen: ((String) throws -> Void)?
    var observeCachedDataCount = 0
    var observeCacheDataThenAnswer: ((MockGetDataRequirements) -> Observable<String>)?
    var isDataEmptyCount = 0

    var maxAgeOfData: Period
    var fakeData: FakeData

    init(fakeData: FakeData, maxAgeOfData: Period) {
        self.fakeData = fakeData
        self.maxAgeOfData = maxAgeOfData
    }

    func fetchFreshData(requirements: MockGetDataRequirements) -> Single<FetchResponse<String>> {
        fetchFreshDataCount += 1
        fetchFreshDataRequirements = requirements
        return fakeData.fetchFreshData
    }

    func saveData(_ fetchedData: String, requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements) throws {
        saveDataCount += 1
        saveDataFetchedData = fetchedData
        try saveDataThen?(fetchedData)
    }

    func observeCachedData(requirements: MockGetDataRequirements) -> Observable<String> {
        observeCachedDataCount += 1
        return observeCacheDataThenAnswer?(requirements) ?? fakeData.observeCachedData
    }

    func isDataEmpty(_ cache: String, requirements: MockOnlineRepositoryDataSource.MockGetDataRequirements) -> Bool {
        isDataEmptyCount += 1
        return fakeData.isDataEmpty
    }

    struct FakeData {
        var isDataEmpty: Bool
        var observeCachedData: Observable<String>
        var fetchFreshData: Single<FetchResponse<String>>
    }

    struct MockGetDataRequirements: OnlineRepositoryGetDataRequirements, Equatable {
        var tag: OnlineRepositoryGetDataRequirements.Tag = "MockGetDataRequirements"

        let randomString: String?

        init(randomString: String?) {
            self.randomString = randomString
        }

        static func == (lhs: MockGetDataRequirements, rhs: MockGetDataRequirements) -> Bool {
            return lhs.tag == rhs.tag && lhs.randomString == rhs.randomString
        }
    }
}
