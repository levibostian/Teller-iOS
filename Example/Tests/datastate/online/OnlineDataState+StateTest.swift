//
//  OnlineDataState+StateTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/19/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Teller

class OnlineDataState_StateTest: XCTestCase {
    
    private var dataState: OnlineDataState<String>!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_cacheState_cacheEmpty() {
        dataState = OnlineDataState.isEmpty()
        XCTAssertEqual(dataState.cacheState(), OnlineDataState.CacheState.cacheEmpty)
    }
    
    func test_cacheState_cacheData() {
        let data = "foo"
        let dataFetched = Date()
        dataState = OnlineDataState.data(data: data, dataFetched: dataFetched)
        XCTAssertEqual(dataState.cacheState(), OnlineDataState.CacheState.cacheData(data: data, fetched: dataFetched))
    }

    func test_cacheState_nil() {
        dataState = OnlineDataState.firstFetchOfData()
        XCTAssertNil(dataState.cacheState())
    }
    
    func test_firstFetchState_firstFetchOfData() {
        dataState = OnlineDataState.firstFetchOfData()
        XCTAssertEqual(dataState.firstFetchState(), OnlineDataState.FirstFetchState.firstFetchOfData)
    }
    
    func test_firstFetchState_finishedFirstFetchOfData() {
        let error = FetchError()
        dataState = OnlineDataState.firstFetchOfData().doneFirstFetch(error: error)
        XCTAssertEqual(dataState.firstFetchState(), OnlineDataState.FirstFetchState.finishedFirstFetchOfData(errorDuringFetch: error))
    }
    
    func test_firstFetchState_nil() {
        dataState = OnlineDataState.isEmpty()
        XCTAssertNil(dataState.firstFetchState())
    }
    
    func test_fetchingFreshDataState_fetchingFreshData() {
        dataState = OnlineDataState.isEmpty().fetchingFreshData()
        XCTAssertEqual(dataState.fetchingFreshDataState(), OnlineDataState.FetchingFreshDataState.fetchingFreshCacheData)
    }
    
    func test_fetchingFreshDataState_finishedFetchingFreshData() {
        let error = FetchError()
        dataState = OnlineDataState.isEmpty().fetchingFreshData().doneFetchingFreshData(errorDuringFetch: error)
        XCTAssertEqual(dataState.fetchingFreshDataState(), OnlineDataState.FetchingFreshDataState.finishedFetchingFreshCacheData(errorDuringFetch: error))
    }
    
    func test_fetchingFreshDataState_nil() {
        dataState = OnlineDataState.isEmpty()
        XCTAssertNil(dataState.fetchingFreshDataState())
    }
    
    class FetchError: Error {
    }
    
}
