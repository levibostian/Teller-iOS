//
//  LocalRepositoryTest.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import Teller

class LocalRepositoryTest: XCTestCase {
    
    private var localRepository: LocalRepository<FakeLocalRepositoryDataSource>!
    private var dataSource: FakeLocalRepositoryDataSource!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func initRepository(dataSource: FakeLocalRepositoryDataSource = FakeLocalRepositoryDataSource(fakeData: LocalRepositoryTest.FakeLocalRepositoryDataSource.FakeData())) {
        self.dataSource = dataSource
        
        self.localRepository = LocalRepository(dataSource: self.dataSource)
    }
    
    func testObserve_onNextEmpty() {
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: true, observeData: Observable.just(""))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))
        
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        self.localRepository.observe().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.isEmpty()])
    }
    
    func testObserve_onNextData() {
        let data: String = "data here"
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: false, observeData: Observable.just(data))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))
        
        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        self.localRepository.observe().subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.data(data: data)])
    }
    
    class FakeLocalRepositoryDataSource: LocalRepositoryDataSource {
        var saveDataCount = 0
        var observeDataCount = 0
        var isDataEmptyCount = 0
        
        struct FakeData {
            var isDataEmpty: Bool
            var observeData: Observable<String>
            
            init(isDataEmpty: Bool = false,
                 observeData: Observable<String> = Observable.empty()) {
                self.isDataEmpty = isDataEmpty
                self.observeData = observeData
            }
        }
        private let fakeData: FakeData
        
        init(fakeData: FakeData) {
            self.fakeData = fakeData
        }
        
        typealias DataType = String
        
        func saveData(data: String) {
            saveDataCount += 1
        }
        func observeData() -> Observable<String> {
            observeDataCount += 1
            return fakeData.observeData
        }
        func isDataEmpty(data: String) -> Bool {
            isDataEmptyCount += 1
            return fakeData.isDataEmpty
        }
    }
    
}
