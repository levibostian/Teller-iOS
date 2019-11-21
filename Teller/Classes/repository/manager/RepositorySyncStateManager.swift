import Foundation

internal protocol RepositorySyncStateManager {
    func isCacheTooOld(tag: RepositoryRequirements.Tag, maxAgeOfCache: Period) -> Bool
    func updateAgeOfData(tag: RepositoryRequirements.Tag, age: Date)
    func hasEverFetchedData(tag: RepositoryRequirements.Tag) -> Bool
    func lastTimeFetchedData(tag: RepositoryRequirements.Tag) -> Date?
}

/**
 * In charge of keeping track of when a repository has been synced last and how old the data is.
 */
internal class TellerRepositorySyncStateManager: RepositorySyncStateManager {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = TellerConstants.userDefaults) {
        self.userDefaults = userDefaults
    }

    func isCacheTooOld(tag: RepositoryRequirements.Tag, maxAgeOfCache: Period) -> Bool {
        if !hasEverFetchedData(tag: tag) {
            return true
        }

        return lastTimeFetchedData(tag: tag)! < maxAgeOfCache.toDate()
    }

    func hasEverFetchedData(tag: RepositoryRequirements.Tag) -> Bool {
        return lastTimeFetchedData(tag: tag) != nil
    }

    func updateAgeOfData(tag: RepositoryRequirements.Tag, age: Date) {
        userDefaults.set(age.timeIntervalSince1970, forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)")
    }

    func lastTimeFetchedData(tag: RepositoryRequirements.Tag) -> Date? {
        let lastFetchedTime = userDefaults.double(forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)")
        guard lastFetchedTime > 0 else { return nil }

        return Date(timeIntervalSince1970: lastFetchedTime)
    }
}
