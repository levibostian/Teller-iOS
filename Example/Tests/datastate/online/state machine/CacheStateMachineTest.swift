//
//  CacheStateMachineTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 11/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class CacheStateMachineTest: XCTestCase {

    private var stateMachine: CacheStateMachine<String>!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_cacheEmpty_setsCorrectProperties() {
        self.stateMachine = CacheStateMachine.cacheEmpty()

        XCTAssertEqual(self.stateMachine.state, CacheStateMachine.State.cacheEmpty)
        XCTAssertNil(self.stateMachine.cache)
    }

    func test_cacheExists_setsCorrectProperties() {
        let cache = "cache"
        self.stateMachine = CacheStateMachine.cacheExists(cache)

        XCTAssertEqual(self.stateMachine.state, CacheStateMachine.State.cacheNotEmpty)
        XCTAssertEqual(self.stateMachine.cache, cache)
    }

}

