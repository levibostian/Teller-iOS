//
//  MockRepositorySyncStateManager.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import Teller

internal class MockRepositorySyncStateManager: RepositorySyncStateManager {
    
    var isDataTooOldCount = 0
    var updateAgeOfDataCount = 0
    var updateAgeOfDataListener: (() -> Bool?)? = nil
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
        return self.fakeData.isDataTooOld
    }
    
    func updateAgeOfData(tag: OnlineRepositoryGetDataRequirements.Tag) {
        updateAgeOfDataCount += 1
        if let newHasEverFetchedData = updateAgeOfDataListener?() {
            self.fakeData.hasEverFetchedData = newHasEverFetchedData
        }
    }
    
    func hasEverFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Bool {
        hasEverFetchedDataCount += 1
        return self.fakeData.hasEverFetchedData
    }
    
    func lastTimeFetchedData(tag: OnlineRepositoryGetDataRequirements.Tag) -> Date? {
        lastTimeFetchedDataCount += 1
        return self.fakeData.lastTimeFetchedData
    }
    
    
}
