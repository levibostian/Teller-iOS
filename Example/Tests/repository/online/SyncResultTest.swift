//
//  SyncResultTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class SyncResultTest: XCTestCase {
    
    private var syncResult: SyncResult!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccess_setsPropertiesCorrectly() {
        syncResult = SyncResult.success()
        
        XCTAssertTrue(syncResult.didSucceed())
        XCTAssertFalse(syncResult.didFail())
        XCTAssertFalse(syncResult.didSkip())
    }

    func testFail_setsPropertiesCorrectly() {
        struct Failure: Error {
            let message: String
        }
        let message = "foo"
        
        syncResult = SyncResult.fail(Failure(message: message))
        
        XCTAssertFalse(syncResult.didSucceed())
        XCTAssertTrue(syncResult.didFail())
        XCTAssertTrue(syncResult.failedError is Failure)
        XCTAssertEqual((syncResult.failedError as! Failure).message, message)
        XCTAssertFalse(syncResult.didSkip())
    }
    
    func testSkip_setsPropertiesCorrectly() {
        syncResult = SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld)
        
        XCTAssertFalse(syncResult.didSucceed())
        XCTAssertFalse(syncResult.didFail())
        XCTAssertTrue(syncResult.didSkip())
        XCTAssertEqual(syncResult.skipped, SyncResult.SkippedReason.dataNotTooOld)
    }
    
}
