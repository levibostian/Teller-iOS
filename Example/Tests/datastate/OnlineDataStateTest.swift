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
    
    func testdeliver_firstFetchOfData_deliversCorrectListener() {
        var listener = StubOnlineDataStateListener()
        
        dataState = OnlineDataState.firstFetchOfData()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 1)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 0)
        XCTAssertEqual(listener.cacheEmptyCount, 0)
        XCTAssertEqual(listener.cacheDataCount, 0)
        
        let error = FetchError()
        dataState = dataState.doneFirstFetch(error: error)
        listener = StubOnlineDataStateListener()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 0)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 1)
        XCTAssertTrue(listener.finishedFirstFetchOfDataError is FetchError)
        XCTAssertEqual(listener.cacheEmptyCount, 0)
        XCTAssertEqual(listener.cacheDataCount, 0)
    }
    
    func testdeliver_isEmtpy_to_fetchingFreshData_deliversCorrectListener() {
        var listener = StubOnlineDataStateListener()
        
        dataState = OnlineDataState.isEmpty()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 0)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 0)
        XCTAssertEqual(listener.cacheEmptyCount, 1)
        XCTAssertEqual(listener.cacheDataCount, 0)
        
        dataState = dataState.fetchingFreshData()
        listener = StubOnlineDataStateListener()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 1)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 0)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 0)
        XCTAssertEqual(listener.cacheEmptyCount, 1) // Empty should *still* be calling listener.
        XCTAssertEqual(listener.cacheDataCount, 0)
    }
    
    func testdeliver_data_to_fetchingFreshData_deliversCorrectListener() {
        var listener = StubOnlineDataStateListener()
        
        let data = "foo"
        let dataFetched = Date()
        dataState = OnlineDataState.data(data: data, dataFetched: dataFetched)
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 0)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 0)
        XCTAssertEqual(listener.cacheEmptyCount, 0)
        XCTAssertEqual(listener.cacheDataCount, 1)
        
        dataState = dataState.fetchingFreshData()
        listener = StubOnlineDataStateListener()
        dataState.deliver(listener: listener)
        
        XCTAssertEqual(listener.fetchingFreshCacheDataCount, 1)
        XCTAssertEqual(listener.finishedFetchingFreshCacheDataCount, 0)
        XCTAssertEqual(listener.firstFetchOfDataCount, 0)
        XCTAssertEqual(listener.finishedFirstFetchOfDataCount, 0)
        XCTAssertEqual(listener.cacheEmptyCount, 0)
        XCTAssertEqual(listener.cacheDataCount, 1) // Empty should *still* be calling listener.
    }
    
    func testdeliver_errorOnlyGetsDeliveredOnce() {
        var listener = StubOnlineDataStateListener()
        
        dataState = OnlineDataState.isEmpty()
        dataState = dataState.fetchingFreshData()
        let error = FetchError()
        dataState = dataState.doneFetchingFreshData(errorDuringFetch: error)
        dataState.deliver(listener: listener)
        
        XCTAssertNotNil(listener.finishedFetchingFreshCacheDataError)
        XCTAssertTrue(listener.finishedFetchingFreshCacheDataError is FetchError)
        
        dataState = dataState.fetchingFreshData()
        
        listener = StubOnlineDataStateListener()
        dataState.deliver(listener: listener)
        
        XCTAssertNil(listener.finishedFetchingFreshCacheDataError)
    }
    
    class FetchError: Error {
    }
    
    class StubOnlineDataStateListener: OnlineDataStateListener {
        var fetchingFreshCacheDataCount = 0
        var finishedFetchingFreshCacheDataError: Error? = nil
        var finishedFetchingFreshCacheDataCount = 0
        var finishedFirstFetchOfDataError: Error? = nil
        var firstFetchOfDataCount = 0
        var finishedFirstFetchOfDataCount = 0
        var cacheEmptyCount = 0
        var cacheDataCount = 0
        
        func fetchingFreshCacheData() {
            fetchingFreshCacheDataCount += 1
        }
        func finishedFetchingFreshCacheData(errorDuringFetch: Error?) {
            finishedFetchingFreshCacheDataError = errorDuringFetch
            finishedFetchingFreshCacheDataCount += 1
        }
        func firstFetchOfData() {
            firstFetchOfDataCount += 1
        }
        func finishedFirstFetchOfData(errorDuringFetch: Error?) {
            finishedFirstFetchOfDataError = errorDuringFetch
            finishedFirstFetchOfDataCount += 1
        }
        func cacheEmpty() {
            cacheEmptyCount += 1
        }
        func cacheData<DataType>(data: DataType, fetched: Date) {
            cacheDataCount += 1
        }
    }
    
}
