//
//  OnlineDataStateTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import Teller

class OnlineDataStateTest: XCTestCase {
    
    private var dataState: OnlineDataState<String>!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_firstFetchOfData() {
        self.dataState = OnlineDataState.firstFetchOfData()
        
        XCTAssertTrue(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertNil(dataState.dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
    }
    
    func test_isEmpty() {
        self.dataState = OnlineDataState.isEmpty()
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertTrue(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertNil(dataState.dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
    }
    
    func test_data() {
        let data = "foo"
        let dataFetched = Date()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
    }
    
    func test_doneFirstFetch() {
        let error = Fail()
        self.dataState = OnlineDataState.firstFetchOfData().doneFirstFetch(error: error)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertTrue(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertNil(dataState.dataFetched)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: error, rhs: dataState.errorDuringFirstFetch))
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
    }
    
    func test_fetchingFreshData() {
        let data = "foo"
        let dataFetched = Date()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched).fetchingFreshData()
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
    }
    
    func test_doneFetchingFreshData() {
        let data = "foo"
        let dataFetched = Date()
        let error = Fail()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched).fetchingFreshData().doneFetchingFreshData(errorDuringFetch: error)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertTrue(dataState.doneFetchingFreshData)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: error, rhs: dataState.errorDuringFetch))
    }
    
    class Fail: Error {
    }
    
}
