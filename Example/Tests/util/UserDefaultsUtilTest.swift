//
//  UserDefaultsUtil.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class UserDefaultsUtilTest: XCTestCase {
    
    override func setUp() {
        super.setUp()

        UserDefaultsUtil.clear()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_clear() {
        let userDefaults = TellerConstants.userDefaults
        func getNumberOfTellerItemsInUserDefaults() -> Int {
            var numberOfTellerItemsInUserDefaults = 0
            userDefaults.dictionaryRepresentation().keys.forEach { (key) in
                if (key.starts(with: TellerConstants.userDefaultsPrefix)) {
                    numberOfTellerItemsInUserDefaults += 1
                }
            }
            return numberOfTellerItemsInUserDefaults
        }
        let numberOfItemsCurrently = getNumberOfTellerItemsInUserDefaults()

        let key = "\(TellerConstants.userDefaultsPrefix)foo"
        userDefaults.set(false, forKey: key)
        userDefaults.set(false, forKey: "fake_\(key)")
        userDefaults.dictionaryRepresentation().keys.forEach { (foo) in
            print("item: \(foo)")
        }
        XCTAssertEqual(getNumberOfTellerItemsInUserDefaults(), numberOfItemsCurrently + 1)
        XCTAssertEqual(userDefaults.dictionaryRepresentation()[key] as! Bool, false)
        
        UserDefaultsUtil.clear()
        XCTAssertEqual(getNumberOfTellerItemsInUserDefaults(), numberOfItemsCurrently) // Because we did not yet delete the "fake_" insertion.
    }
    
}
