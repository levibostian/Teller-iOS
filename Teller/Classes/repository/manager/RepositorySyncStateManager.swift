//
//  RepositorySyncStateManager.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

internal protocol RepositorySyncStateManager {
    func isDataTooOld(tag: OnlineRepositoryGetDataRequirements.Tag, maxAgeOfData: Period) -> Bool
    func updateLastTimeFreshDataFetched(tag: OnlineRepositoryGetDataRequirements.Tag)
    func hasEverFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Bool
    func lastTimeFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Date?
}

/**
 * In charge of keeping track of when a repository has been synced last and how old the data is.
 */
internal class TellerRepositorySyncStateManager: RepositorySyncStateManager {
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = TellerConstants.userDefaults) {
        self.userDefaults = userDefaults
    }
    
    func isDataTooOld(tag: OnlineRepositoryGetDataRequirements.Tag, maxAgeOfData: Period) -> Bool {
        if (!self.hasEverFetchedData(tag: tag)) {
            return true
        }
        
        return self.lastTimeFetchedData(tag: tag)! > maxAgeOfData.toDate()
    }
    
    func hasEverFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Bool {
        return lastTimeFetchedData(tag: tag) != nil
    }
    
    func updateLastTimeFreshDataFetched(tag: OnlineRepositoryGetDataRequirements.Tag) {
        userDefaults.set(Date().timeIntervalSince1970, forKey: tag)
    }
    
    func lastTimeFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Date? {
        let lastFetchedTime = userDefaults.double(forKey: tag)
        guard lastFetchedTime > 0 else { return nil }
        
        return Date(timeIntervalSince1970: lastFetchedTime)
    }
    
}
