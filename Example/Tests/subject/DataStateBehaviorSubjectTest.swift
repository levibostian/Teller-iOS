import RxSwift
import RxTest
@testable import Teller
import XCTest

class DataStateBehaviorSubjectTest: XCTestCase {
    private var subject: DataStateBehaviorSubject<String>!
    private var compositeDisposable: CompositeDisposable!

    override func setUp() {
        super.setUp()

        subject = DataStateBehaviorSubject()
        compositeDisposable = CompositeDisposable()
    }

    override func tearDown() {
        compositeDisposable.dispose()
        compositeDisposable = nil

        super.tearDown()
    }

    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [DataState<String>.none()])
    }

    func test_resetStateToNone_receiveNoDataState() {
        subject.resetStateToNone()

        let observer = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [DataState<String>.none()])
    }

    func test_resetToNoCacheState_receiveCorrectDataState() {
        let requirements = MockRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [DataStateStateMachine.noCacheExists(requirements: requirements)])
    }

    func test_resetToCacheState_receiveCorrectDataState() {
        let requirements = MockRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        let lastTimeFetched = Date()
        subject.resetToCacheState(requirements: requirements, lastTimeFetched: lastTimeFetched)

        let observer = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [DataStateStateMachine.cacheExists(requirements: requirements, lastTimeFetched: lastTimeFetched)])
    }

    func test_changeState_sendsResultToSubject() {
        let requirements = MockRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer)

        subject.changeState { try! $0.firstFetch() }

        XCTAssertRecordedElements(observer.events, [
            DataStateStateMachine.noCacheExists(requirements: requirements),
            try! DataStateStateMachine.noCacheExists(requirements: requirements).change().firstFetch()
        ])
    }

    func test_multipleObservers_receiveDifferentNumberOfEvents() {
        let requirements = MockRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetStateToNone()
        subject.resetToNoCacheState(requirements: requirements)
        subject.changeState { try! $0.firstFetch() }

        let observer1 = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer1)
        let fetched = Date()
        subject.changeState { try! $0.successfulFirstFetch(timeFetched: fetched) }
        let observer2 = TestScheduler(initialClock: 0).createObserver(DataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer2)

        let data = "foo"
        subject.changeState { try! $0.cachedData(data) }

        XCTAssertRecordedElements(observer1.events, [
            try! DataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch(),
            try! DataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch().change()
                .successfulFirstFetch(timeFetched: fetched),
            try! DataStateStateMachine
                .cacheExists(requirements: requirements, lastTimeFetched: fetched).change()
                .cachedData(data)
        ])
        XCTAssertEqual(observer2.events, Array(observer1.events[1..<observer1.events.count]))
    }

    private class Fail: Error {}
}
