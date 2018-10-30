//
//  MockOnlineRepositoryDataSource.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
@testable import Teller

internal class MockOnlineRepositoryDataSource: OnlineRepositoryDataSource {
    
    typealias Cache = String
    typealias GetDataRequirements = MockGetDataRequirements
    typealias FetchResult = String
    
    var fetchFreshDataCount = 0
    var fetchFreshDataRequirements: MockGetDataRequirements? = nil
    var saveDataCount = 0
    var saveDataFetchedData: String? = nil
    var observeCachedDataCount = 0
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
        return self.fakeData.fetchFreshData
    }
    
    func saveData(_ fetchedData: String) {
        saveDataCount += 1
        saveDataFetchedData = fetchedData
    }
    
    func observeCachedData(requirements: MockGetDataRequirements) -> Observable<String> {
        observeCachedDataCount += 1
        return self.fakeData.observeCachedData
    }
    
    func isDataEmpty(_ cache: String) -> Bool {
        isDataEmptyCount += 1
        return self.fakeData.isDataEmpty
    }    
    
    struct FakeData {
        var isDataEmpty: Bool
        var observeCachedData: Observable<String>
        var fetchFreshData: Single<FetchResponse<String>>
    }
    
    struct MockGetDataRequirements: OnlineRepositoryGetDataRequirements, Equatable {
        var tag: OnlineRepositoryGetDataRequirements.Tag = "MockGetDataRequirements"
        
        static func == (lhs: MockGetDataRequirements, rhs: MockGetDataRequirements) -> Bool {
            return lhs.tag == rhs.tag
        }
    }
}
