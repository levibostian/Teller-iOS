//
//  FetchResponseTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class FetchResponseTest: XCTestCase {
    
    private var fetchResponse: FetchResponse<Any>!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccess_setsPropertiesCorrectly() {
        let data = "foo"
        fetchResponse = FetchResponse.success(data: data)
        
        XCTAssertTrue(fetchResponse.isSuccessful())
        XCTAssertFalse(fetchResponse.isFailure())
    }
    
    func testFailMessage_setsPropertiesCorrectly() {
        let message = "error message here"
        fetchResponse = FetchResponse.fail(message: message)
        
        XCTAssertFalse(fetchResponse.isSuccessful())
        XCTAssertTrue(fetchResponse.isFailure())
        XCTAssertTrue(fetchResponse.failure is FetchResponse<Any>.FetchFailure)
        XCTAssertEqual((fetchResponse.failure as! FetchResponse<Any>.FetchFailure).message, message)
    }
    
    func testFailError_setsPropertiesCorrectly() {
        let error = Failure()
        fetchResponse = FetchResponse.fail(error: error)
        
        XCTAssertFalse(fetchResponse.isSuccessful())
        XCTAssertTrue(fetchResponse.isFailure())
        XCTAssertTrue(fetchResponse.failure is Failure)
    }
    
    class Failure: Error {
    }
    
}
