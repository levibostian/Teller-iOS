//
//  LocalDataStateTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class LocalDataStateTest: XCTestCase {
    
    private var dataState: LocalDataState<String>!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }
    
    func testIsEmpty_setsPropertiesCorrectly() {
        dataState = LocalDataState.isEmpty()
        
        XCTAssertTrue(dataState.isEmpty)
        XCTAssertNil(dataState.data)
    }
    
    func testData_setsPropertiesCorrectly() {
        let data = "foo"
        dataState = LocalDataState.data(data: data)
        
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
    }
    
    func testDeliver_empty_callsFunctions() {
        let listener = StubLocalDataStateListener()
        
        dataState = LocalDataState.isEmpty()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.isEmptyCount, 1)
        XCTAssertEqual(listener.dataCount, 0)
    }
    
    func testDeliver_data_callsFunctions() {
        let listener = StubLocalDataStateListener()
        let data = "foo"
        
        dataState = LocalDataState.data(data: data)
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.isEmptyCount, 0)
        XCTAssertEqual(listener.dataCount, 1)
    }
    
    class StubLocalDataStateListener: LocalDataStateListener {
        var isEmptyCount = 0
        var dataCount = 0
        
        func isEmpty() {
            isEmptyCount += 1
        }
        func data<DataType>(data: DataType) {
            dataCount += 1
        }
    }
    
}
