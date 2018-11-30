//
//  NoCacheStateMachineTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 11/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class NoCacheStateMachineTest: XCTestCase {

    private var stateMachine: NoCacheStateMachine!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_noCacheExists_setsCorrectProperties() {
        self.stateMachine = NoCacheStateMachine.noCacheExists()

        XCTAssertEqual(self.stateMachine.state, NoCacheStateMachine.State.noCacheExists)
        XCTAssertNil(self.stateMachine.errorDuringFetch)
    }

    func test_fetching_setsCorrectProperties() {
        self.stateMachine = NoCacheStateMachine.noCacheExists().fetching()

        XCTAssertEqual(self.stateMachine.state, NoCacheStateMachine.State.isFetching)
        XCTAssertNil(self.stateMachine.errorDuringFetch)
    }

    func test_failedFetching_setsCorrectProperties() {
        let fail = Failure()
        self.stateMachine = NoCacheStateMachine.noCacheExists().fetching().failedFetching(error: fail)

        XCTAssertEqual(self.stateMachine.state, NoCacheStateMachine.State.noCacheExists)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: self.stateMachine.errorDuringFetch, rhs: fail))
    }

    class Failure: Error {
    }

}
