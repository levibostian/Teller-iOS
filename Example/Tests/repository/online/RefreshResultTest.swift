//
//  RefreshResultTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class RefreshResultTest: XCTestCase {
    
    private var refreshResult: RefreshResult!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccess_setsPropertiesCorrectly() {
        refreshResult = RefreshResult.success()
        
        XCTAssertTrue(refreshResult.didSucceed())
        XCTAssertFalse(refreshResult.didFail())
        XCTAssertFalse(refreshResult.didSkip())
    }

    func testFail_setsPropertiesCorrectly() {
        struct Failure: Error {
            let message: String
        }
        let message = "foo"
        
        refreshResult = RefreshResult.fail(Failure(message: message))
        
        XCTAssertFalse(refreshResult.didSucceed())
        XCTAssertTrue(refreshResult.didFail())
        XCTAssertTrue(refreshResult.failedError is Failure)
        XCTAssertEqual((refreshResult.failedError as! Failure).message, message)
        XCTAssertFalse(refreshResult.didSkip())
    }
    
    func testSkip_setsPropertiesCorrectly() {
        refreshResult = RefreshResult.skipped(RefreshResult.SkippedReason.dataNotTooOld)
        
        XCTAssertFalse(refreshResult.didSucceed())
        XCTAssertFalse(refreshResult.didFail())
        XCTAssertTrue(refreshResult.didSkip())
        XCTAssertEqual(refreshResult.skipped, RefreshResult.SkippedReason.dataNotTooOld)
    }
    
}
