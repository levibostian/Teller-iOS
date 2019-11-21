import RxSwift
import RxTest
@testable import Teller
import XCTest

class OnlineDataStateBehaviorSubjectTest: XCTestCase {
    private var subject: OnlineDataStateBehaviorSubject<String>!
    private var compositeDisposable: CompositeDisposable!

    override func setUp() {
        super.setUp()

        subject = OnlineDataStateBehaviorSubject()
        compositeDisposable = CompositeDisposable()
    }

    override func tearDown() {
        compositeDisposable.dispose()
        compositeDisposable = nil

        super.tearDown()
    }

    func testInit() {
        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
    }

    func test_resetStateToNone_receiveNoDataState() {
        subject.resetStateToNone()

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataState<String>.none()])
    }

    func test_resetToNoCacheState_receiveCorrectDataState() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataStateStateMachine.noCacheExists(requirements: requirements)])
    }

    func test_resetToCacheState_receiveCorrectDataState() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        let lastTimeFetched = Date()
        subject.resetToCacheState(requirements: requirements, lastTimeFetched: lastTimeFetched)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        subject.subject.subscribe(observer).dispose()

        XCTAssertRecordedElements(observer.events, [OnlineDataStateStateMachine.cacheExists(requirements: requirements, lastTimeFetched: lastTimeFetched)])
    }

    func test_changeState_sendsResultToSubject() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetToNoCacheState(requirements: requirements)

        let observer = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer)

        subject.changeState { try! $0.firstFetch() }

        XCTAssertRecordedElements(observer.events, [
            OnlineDataStateStateMachine.noCacheExists(requirements: requirements),
            try! OnlineDataStateStateMachine.noCacheExists(requirements: requirements).change().firstFetch()
        ])
    }

    func test_multipleObservers_receiveDifferentNumberOfEvents() {
        let requirements = MockOnlineRepositoryDataSource.MockGetDataRequirements(randomString: nil)
        subject.resetStateToNone()
        subject.resetToNoCacheState(requirements: requirements)
        subject.changeState { try! $0.firstFetch() }

        let observer1 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer1)
        let fetched = Date()
        subject.changeState { try! $0.successfulFirstFetch(timeFetched: fetched) }
        let observer2 = TestScheduler(initialClock: 0).createObserver(OnlineDataState<String>.self)
        compositeDisposable += subject.subject.subscribe(observer2)

        let data = "foo"
        subject.changeState { try! $0.cachedData(data) }

        XCTAssertRecordedElements(observer1.events, [
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch(),
            try! OnlineDataStateStateMachine
                .noCacheExists(requirements: requirements).change()
                .firstFetch().change()
                .successfulFirstFetch(timeFetched: fetched),
            try! OnlineDataStateStateMachine
                .cacheExists(requirements: requirements, lastTimeFetched: fetched).change()
                .cachedData(data)
        ])
        XCTAssertEqual(observer2.events, Array(observer1.events[1..<observer1.events.count]))
    }

    private class Fail: Error {}
}
