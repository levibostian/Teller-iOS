import Foundation
@testable import Teller

internal class MockRepositorySyncStateManager: RepositorySyncStateManager {
    var isDataTooOldCount = 0
    var updateAgeOfDataCount = 0
    var updateAgeOfDataListener: (() -> Bool?)?
    var updateAgeOfData_age: Date?
    var hasEverFetchedDataCount = 0
    var lastTimeFetchedDataCount = 0

    struct FakeData {
        var isDataTooOld: Bool
        var hasEverFetchedData: Bool
        var lastTimeFetchedData: Date?
    }

    var fakeData: FakeData

    init(fakeData: FakeData) {
        self.fakeData = fakeData
    }

    func isDataTooOld(tag: OnlineRepositoryGetDataRequirements.Tag, maxAgeOfData: Period) -> Bool {
        isDataTooOldCount += 1
        return fakeData.isDataTooOld
    }

    func updateAgeOfData(tag: OnlineRepositoryGetDataRequirements.Tag, age: Date) {
        updateAgeOfDataCount += 1
        updateAgeOfData_age = age
        if let newHasEverFetchedData = updateAgeOfDataListener?() {
            fakeData.hasEverFetchedData = newHasEverFetchedData
        }
    }

    func hasEverFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Bool {
        hasEverFetchedDataCount += 1
        return fakeData.hasEverFetchedData
    }

    func lastTimeFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Date? {
        lastTimeFetchedDataCount += 1
        return fakeData.lastTimeFetchedData
    }
}
