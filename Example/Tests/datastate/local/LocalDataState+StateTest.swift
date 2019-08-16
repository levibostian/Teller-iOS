//
//  LocalDataState+StateTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class LocalDataState_StateTest: XCTestCase {
    
    private var dataState: LocalDataState<String>!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here.
        super.tearDown()
    }

    func test_state_none() {
        dataState = LocalDataState.none()
        XCTAssertNil(dataState.state())
    }
    
    func test_state_empty() {
        dataState = LocalDataState.isEmpty()
        XCTAssertEqual(dataState.state(), LocalDataState<String>.State.isEmpty(error: nil))
    }
    
    func test_state_data() {
        let data = "foo"
        dataState = LocalDataState.data(data: data)
        XCTAssertEqual(dataState.state(), LocalDataState.State.data(data: data, error: nil))
    }

    func test_state_emptyError() {
        let error = Fail()
        dataState = LocalDataState.isEmpty().errorOccurred(error)
        XCTAssertEqual(dataState.state(), LocalDataState.State.isEmpty(error: error))
    }

    func test_state_dataError() {
        let error = Fail()
        let data = "foo"
        dataState = LocalDataState.data(data: data).errorOccurred(error)
        XCTAssertEqual(dataState.state(), LocalDataState.State.data(data: data, error: error))
    }

    func test_notEqual() {
        dataState = LocalDataState.data(data: "foo")
        XCTAssertNotEqual(dataState.state(), LocalDataState<String>.State.isEmpty(error: nil))
    }

    private class Fail: Error {
    }
}
