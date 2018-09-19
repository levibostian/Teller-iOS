//
//  PeriodTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class PeriodTest: XCTestCase {
    
    private var period: Period!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_toDate() {
        self.period = Period(unit: 1, component: Calendar.Component.second)
        XCTAssertLessThan(self.period.toDate().timeIntervalSince1970, Date().timeIntervalSince1970)
        
        let lessThan = Period(unit: 2, component: Calendar.Component.second)
        let olderThan = Period(unit: 1, component: Calendar.Component.second)
        XCTAssertLessThan(lessThan.toDate().timeIntervalSince1970, olderThan.toDate().timeIntervalSince1970)
    }
    
}
