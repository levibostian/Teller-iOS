//
//  TellerTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 12/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class TellerTest: XCTestCase {

    private var userDefaultsUtilMock: UserDefaultsUtilMock!
    private var teller: Teller!

    override func setUp() {
        super.setUp()

        userDefaultsUtilMock = UserDefaultsUtilMock()
        teller = Teller(userDefaultsUtil: userDefaultsUtilMock)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_clear_deletesAllData() {
        teller.clear()

        XCTAssertTrue(userDefaultsUtilMock.invokedClear)
        XCTAssertEqual(userDefaultsUtilMock.invokedClearCount, 1)
    }

}
