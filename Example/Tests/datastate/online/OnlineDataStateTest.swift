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
    let getDataRequirements = MockOnlineRepositoryDataSource.MockGetDataRequirements()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_firstFetchOfData() {
        self.dataState = OnlineDataState.firstFetchOfData(getDataRequirements: getDataRequirements)
        
        XCTAssertTrue(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertNil(dataState.dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    func test_isEmpty() {
        let dataFetched = Date()
        self.dataState = OnlineDataState.isEmpty(getDataRequirements: getDataRequirements, dataFetched: dataFetched)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertTrue(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    func test_data() {
        let data = "foo"
        let dataFetched = Date()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched, getDataRequirements: getDataRequirements)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    func test_doneFirstFetch() {
        let error = Fail()
        self.dataState = OnlineDataState.firstFetchOfData(getDataRequirements: getDataRequirements).doneFirstFetch(error: error)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertTrue(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertNil(dataState.data)
        XCTAssertNil(dataState.dataFetched)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: error, rhs: dataState.errorDuringFirstFetch))
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    func test_fetchingFreshData() {
        let data = "foo"
        let dataFetched = Date()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched, getDataRequirements: getDataRequirements).fetchingFreshData()
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertTrue(dataState.isFetchingFreshData)
        XCTAssertFalse(dataState.doneFetchingFreshData)
        XCTAssertNil(dataState.errorDuringFetch)
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    func test_doneFetchingFreshData() {
        let data = "foo"
        let dataFetched = Date()
        let error = Fail()
        self.dataState = OnlineDataState.data(data: data, dataFetched: dataFetched, getDataRequirements: getDataRequirements).fetchingFreshData().doneFetchingFreshData(errorDuringFetch: error)
        
        XCTAssertFalse(dataState.firstFetchOfData)
        XCTAssertFalse(dataState.doneFirstFetchOfData)
        XCTAssertFalse(dataState.isEmpty)
        XCTAssertEqual(dataState.data, data)
        XCTAssertEqual(dataState.dataFetched, dataFetched)
        XCTAssertNil(dataState.errorDuringFirstFetch)
        XCTAssertFalse(dataState.isFetchingFreshData)
        XCTAssertTrue(dataState.doneFetchingFreshData)
        XCTAssertTrue(ErrorsUtil.areErrorsEqual(lhs: error, rhs: dataState.errorDuringFetch))
        XCTAssertEqual(dataState.getDataRequirements as! MockOnlineRepositoryDataSource.MockGetDataRequirements, getDataRequirements)
    }
    
    class Fail: Error {
    }
    
}
