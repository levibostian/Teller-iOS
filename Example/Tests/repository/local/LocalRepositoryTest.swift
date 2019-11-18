import RxSwift
import RxTest
@testable import Teller
import XCTest

class LocalRepositoryTest: XCTestCase {
    private var localRepository: LocalRepository<FakeLocalRepositoryDataSource>!
    private var dataSource: FakeLocalRepositoryDataSource!

    private var compositeDisposable: CompositeDisposable!

    override func setUp() {
        super.setUp()

        compositeDisposable = CompositeDisposable()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        compositeDisposable.dispose()
        compositeDisposable = nil
    }

    private func initRepository(dataSource: FakeLocalRepositoryDataSource = FakeLocalRepositoryDataSource(fakeData: LocalRepositoryTest.FakeLocalRepositoryDataSource.FakeData()), requirements: FakeLocalGetDataRequirements? = FakeLocalGetDataRequirements(), setRequirements: Bool = true) {
        self.dataSource = dataSource

        localRepository = LocalRepository(dataSource: self.dataSource, schedulersProvider: TestsSchedulersProvider())

        if setRequirements {
            localRepository.requirements = requirements
        }
    }

    func test_observe_requirementsNotSet_willReceiveEventsOnceRequirementsSet() {
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: true, observeData: Observable.just(""))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData), requirements: nil, setRequirements: false)

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += localRepository.observe().subscribe(observer)

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.none()])

        localRepository.requirements = FakeLocalGetDataRequirements()

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.none(),
                                                    LocalDataState<String>.none(), // 2nd .none() call since calling resetStateToNone()
                                                    LocalDataState<String>.isEmpty()])
    }

    func test_observe_onNextEmpty() {
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: true, observeData: Observable.just(""))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        localRepository.observe().subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.isEmpty()])
    }

    func testObserve_onNextData() {
        let data: String = "data here"
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: false, observeData: Observable.just(data))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        localRepository.observe().subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.data(data: data)])
    }

    func test_newCache_callsDataSource() {
        let data: String = "data here"
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: false, observeData: Observable.just(data))
        let dataSource = LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData)
        initRepository(dataSource: dataSource)

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        localRepository.observe().subscribe(observer).dispose()

        let saveCacheExpectation = expectation(description: "Expect to save cache")
        dataSource.saveCacheThen = { cache in
            saveCacheExpectation.fulfill()
        }

        localRepository.newCache(data)

        wait(for: [saveCacheExpectation], timeout: TestConstants.AWAIT_DURATION)
        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.data(data: data)])
    }

    func test_newCache_callsDataSource_failSaving() {
        let data: String = "data here"
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: false, observeData: Observable.just(data))
        let dataSource = LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData)
        initRepository(dataSource: dataSource)

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        localRepository.observe().subscribe(observer).dispose()

        let saveCacheError = Fail()
        dataSource.saveCacheThen = { cache in
            throw saveCacheError
        }

        localRepository.newCache(data)

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.data(data: data).errorOccurred(saveCacheError)])
    }

    func test_disposeRepository_disposesObservers() {
        let data: String = "data here"
        let observeCacheObservable: PublishSubject<String> = PublishSubject()
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: false, observeData: observeCacheObservable)
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += localRepository.observe().subscribe(observer)

        observeCacheObservable.onNext(data)

        localRepository = nil

        observeCacheObservable.onNext("This will never get to observer")

        XCTAssertEqual(observer.events, [
            Recorded.next(0, LocalDataState<String>.none()),
            Recorded.next(0, LocalDataState<String>.data(data: data)),
            Recorded.completed(0)
        ])
    }

    func test_observe_multipleObservers() {
        let fakeData = FakeLocalRepositoryDataSource.FakeData(isDataEmpty: true, observeData: Observable.just(""))
        initRepository(dataSource: LocalRepositoryTest.FakeLocalRepositoryDataSource(fakeData: fakeData))

        let observer = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += localRepository.observe().subscribe(observer)

        let observer2 = TestScheduler(initialClock: 0).createObserver(LocalDataState<String>.self)
        compositeDisposable += localRepository.observe().subscribe(observer2)

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.isEmpty()])
        XCTAssertRecordedElements(observer2.events, [LocalDataState<String>.isEmpty()])

        localRepository.requirements = FakeLocalGetDataRequirements()

        XCTAssertRecordedElements(observer.events, [LocalDataState<String>.isEmpty(),
                                                    LocalDataState<String>.none(), // Call to resetStateToNone()
                                                    LocalDataState<String>.isEmpty()])
        XCTAssertRecordedElements(observer2.events, [LocalDataState<String>.isEmpty(),
                                                     LocalDataState<String>.none(), // Call to resetStateToNone()
                                                     LocalDataState<String>.isEmpty()])
    }

    class FakeLocalGetDataRequirements: LocalRepositoryGetDataRequirements {}

    class FakeLocalRepositoryDataSource: LocalRepositoryDataSource {
        typealias Cache = String
        typealias GetDataRequirements = FakeLocalGetDataRequirements

        var saveDataCount = 0
        var observeDataCount = 0
        var isDataEmptyCount = 0

        var saveCacheThen: ((String) throws -> Void)?

        struct FakeData {
            var isDataEmpty: Bool
            var observeData: Observable<String>

            init(isDataEmpty: Bool = false,
                 observeData: Observable<String> = Observable.empty()) {
                self.isDataEmpty = isDataEmpty
                self.observeData = observeData
            }
        }

        var fakeData: FakeData

        init(fakeData: FakeData) {
            self.fakeData = fakeData
        }

        typealias DataType = String

        func saveData(data: String) throws {
            try saveCacheThen?(data)
            saveDataCount += 1
        }

        func observeCachedData() -> Observable<String> {
            observeDataCount += 1
            return fakeData.observeData
        }

        func isDataEmpty(data: String) -> Bool {
            isDataEmptyCount += 1
            return fakeData.isDataEmpty
        }
    }

    private class Fail: Error {}
}
