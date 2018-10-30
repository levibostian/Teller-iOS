//
//  TellerRepositorySyncStateManagerTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class TellerRepositorySyncStateManagerTest: XCTestCase {
    
    private var tellerRepositorySyncStateManager: TellerRepositorySyncStateManager!
    private var userDefaults: UserDefaults!
    
    private let tag: OnlineRepositoryGetDataRequirements.Tag = "tag here"
    
    override func setUp() {
        super.setUp()
        
        UserDefaultsUtil.clear()
        userDefaults = TellerConstants.userDefaults
    }
    
    override func tearDown() {
        UserDefaultsUtil.clear()
        
        super.tearDown()
    }
    
    private func initManager() {
        self.tellerRepositorySyncStateManager = TellerRepositorySyncStateManager(userDefaults: self.userDefaults)
    }
    
    func test_isDataTooOld_dataNeverFetchedBefore() {
        initManager()
        
        let isDataTooOld = tellerRepositorySyncStateManager.isDataTooOld(tag: tag, maxAgeOfData: Period(unit: 1, component: Calendar.Component.hour))
        
        XCTAssertTrue(isDataTooOld)
    }
    
    func test_isDataTooOld_dataNotTooOld() {
        initManager()
        
        let dateLastUpdated = Date()
        userDefaults.set(dateLastUpdated.timeIntervalSince1970, forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)")
        
        let isDataTooOld = tellerRepositorySyncStateManager.isDataTooOld(tag: tag, maxAgeOfData: Period(unit: 1, component: Calendar.Component.second))
        
        XCTAssertFalse(isDataTooOld)
    }
    
    func test_isDataTooOld_dataTooOld() {
        initManager()
        
        let olderDate: Date = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        userDefaults.set(olderDate.timeIntervalSince1970, forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)")
        
        let isDataTooOld = tellerRepositorySyncStateManager.isDataTooOld(tag: tag, maxAgeOfData: Period(unit: 1, component: Calendar.Component.second))
        
        XCTAssertTrue(isDataTooOld)
    }
    
    func test_hasEverFetchedData_false() {
        initManager()
        
        XCTAssertFalse(tellerRepositorySyncStateManager.hasEverFetchedData(tag: tag))
    }
    
    func test_hasEverFetchedData_true() {
        initManager()
        
        tellerRepositorySyncStateManager.updateAgeOfData(tag: tag)
        XCTAssertTrue(tellerRepositorySyncStateManager.hasEverFetchedData(tag: tag))
    }
    
    func test_updateLastTimeFreshDataFetched_timeUpdated() {
        initManager()
        
        XCTAssertEqual(userDefaults.double(forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)"), 0) // 0 means it has never been set.
        
        tellerRepositorySyncStateManager.updateAgeOfData(tag: tag)
        
        let dateLastUpdatedMinusOneSecond = Date().addingTimeInterval(TimeInterval(-1))
        XCTAssertGreaterThan(userDefaults.double(forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)"), dateLastUpdatedMinusOneSecond.timeIntervalSince1970)
    }
    
    func test_lastTimeFetchedData() {
        initManager()
        
        XCTAssertNil(tellerRepositorySyncStateManager.lastTimeFetchedData(tag: tag))
        
        let date = Date()
        userDefaults.set(date.timeIntervalSince1970, forKey: "\(TellerConstants.userDefaultsPrefix)\(tag)")
        
        XCTAssertEqual(tellerRepositorySyncStateManager.lastTimeFetchedData(tag: tag)!.timeIntervalSince1970, date.timeIntervalSince1970)
    }
    
}
