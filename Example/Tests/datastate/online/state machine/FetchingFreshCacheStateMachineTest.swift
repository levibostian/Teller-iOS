//
//  FetchingFreshCacheStateMachineTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 11/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class FetchingFreshCacheStateMachineTest: XCTestCase {

    private var stateMachine: FetchingFreshCacheStateMachine!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_notFetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched)

        XCTAssertEqual(self.stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertNil(self.stateMachine.errorDuringFetch)
        XCTAssertEqual(self.stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_fetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        self.stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching()

        XCTAssertEqual(self.stateMachine.state, FetchingFreshCacheStateMachine.State.isFetching)
        XCTAssertNil(self.stateMachine.errorDuringFetch)
        XCTAssertEqual(self.stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_failedFetching_setsCorrectProperties() {
        let lastTimeFetched = Date()
        let fail = Failure()
        self.stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching().failedFetching(fail)

        XCTAssertEqual(self.stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: self.stateMachine.errorDuringFetch, rhs: fail))
        XCTAssertEqual(self.stateMachine.lastTimeFetched, lastTimeFetched)
    }

    func test_successfulFetch_setsCorrectProperties() {
        let lastTimeFetched = Date()
        let newTimeFetched = Date(timeIntervalSince1970: lastTimeFetched.timeIntervalSince1970 + 1)
        self.stateMachine = FetchingFreshCacheStateMachine.notFetching(lastTimeFetched: lastTimeFetched).fetching().successfulFetch(timeFetched: newTimeFetched)

        XCTAssertEqual(self.stateMachine.state, FetchingFreshCacheStateMachine.State.notFetching)
        XCTAssertNil(self.stateMachine.errorDuringFetch)
        XCTAssertEqual(self.stateMachine.lastTimeFetched, newTimeFetched)
    }

    class Failure: Error {
    }

}

