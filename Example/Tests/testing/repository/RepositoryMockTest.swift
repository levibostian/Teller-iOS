import RxBlocking
import RxSwift
@testable import Teller
import XCTest

class RepositoryMockTest: XCTestCase {
    var repository: TellerRepositoryMock<ReposRepositoryDataSource>!
    let defaultRequirements = ReposRepositoryDataSource.Requirements(username: "")

    override func setUp() {
        repository = TellerRepositoryMock(dataSource: ReposRepositoryDataSource())
    }

    // MARK: - requirements

    func test_requirements_expectMockOnlyAfterSet() {
        XCTAssertFalse(repository.mockCalled)

        repository.requirements = ReposRepositoryDataSource.Requirements(username: "")

        XCTAssertTrue(repository.mockCalled)
    }

    func test_requirements_expectCalledOnlyAfterSet() {
        XCTAssertFalse(repository.requirementsCalled)

        repository.requirements = ReposRepositoryDataSource.Requirements(username: "")

        XCTAssertTrue(repository.requirementsCalled)

        repository.requirements = ReposRepositoryDataSource.Requirements(username: "")

        XCTAssertTrue(repository.requirementsCalled)
    }

    func test_requirements_expectCalledCountIncrementAfterSet() {
        XCTAssertEqual(repository.requirementsCallsCount, 0)

        repository.requirements = ReposRepositoryDataSource.Requirements(username: "")

        XCTAssertEqual(repository.requirementsCallsCount, 1)

        repository.requirements = ReposRepositoryDataSource.Requirements(username: "")

        XCTAssertEqual(repository.requirementsCallsCount, 2)
    }

    func test_requirements_expectInvocationsAppendsAfterSet() {
        XCTAssertTrue(repository.requirementsInvocations.isEmpty)

        let givenFirstRequirements = ReposRepositoryDataSource.Requirements(username: "first")
        repository.requirements = givenFirstRequirements

        XCTAssertEqual(repository.requirementsInvocations[0]?.username, givenFirstRequirements.username)

        let givenSecondRequirements = ReposRepositoryDataSource.Requirements(username: "second")
        repository.requirements = givenSecondRequirements

        XCTAssertEqual(repository.requirementsInvocations[0]?.username, givenFirstRequirements.username)
        XCTAssertEqual(repository.requirementsInvocations[1]?.username, givenSecondRequirements.username)
    }

    // MARK: - refresh

    func test_refresh_expectMockOnlyAfterSet() {
        repository.refreshClosure = { _ in
            Single.just(RefreshResult.successful)
        }

        XCTAssertFalse(repository.mockCalled)

        repository.requirements = defaultRequirements
        _ = try! repository.refresh(force: false)

        XCTAssertTrue(repository.mockCalled)
    }

    func test_refresh_expectCalledOnlyAfterSet() {
        repository.requirements = defaultRequirements
        repository.refreshClosure = { _ in
            Single.just(RefreshResult.successful)
        }

        XCTAssertFalse(repository.refreshCalled)

        _ = try! repository.refresh(force: false)

        XCTAssertTrue(repository.refreshCalled)

        _ = try! repository.refresh(force: false)

        XCTAssertTrue(repository.refreshCalled)
    }

    func test_refresh_expectCalledCountIncrementAfterSet() {
        repository.requirements = defaultRequirements
        repository.refreshClosure = { _ in
            Single.just(RefreshResult.successful)
        }

        XCTAssertEqual(repository.refreshCallsCount, 0)

        _ = try! repository.refresh(force: false)

        XCTAssertEqual(repository.refreshCallsCount, 1)

        _ = try! repository.refresh(force: false)

        XCTAssertEqual(repository.refreshCallsCount, 2)
    }

    func test_refresh_expectInvocationsAppendsAfterSet() {
        repository.requirements = defaultRequirements
        var givenInvocations: [Bool] = [
            false,
            true
        ]
        let expectedInvocations = givenInvocations

        repository.refreshClosure = { _ in
            Single.just(RefreshResult.successful)
        }

        XCTAssertTrue(repository.refreshInvocations.isEmpty)

        _ = try! repository.refresh(force: givenInvocations.removeFirst())

        XCTAssertEqual(repository.refreshInvocations[0], expectedInvocations[0])

        _ = try! repository.refresh(force: givenInvocations.removeFirst())

        XCTAssertEqual(repository.refreshInvocations[0], expectedInvocations[0])
        XCTAssertEqual(repository.refreshInvocations[1], expectedInvocations[1])
    }

    func test_refresh_expectReturnsFromClosure() {
        repository.requirements = defaultRequirements
        var givenInvocations: [RefreshResult] = [
            RefreshResult.successful,
            RefreshResult.skipped(reason: .cancelled)
        ]
        let expectedInvocations = givenInvocations

        repository.refreshClosure = { _ in
            Single.just(givenInvocations.removeFirst())
        }

        let actualFirstResult = try! repository.refresh(force: false).toBlocking().first()!

        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = try! repository.refresh(force: false).toBlocking().first()!

        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }

    func test_refresh_givenNoRequirements_expectThrows() {
        XCTAssertThrowsError(_ = try repository.refreshIfNoCache().toBlocking().first())
    }

    // MARK: - refreshIfNoCache

    func test_refreshIfNoCache_expectMockOnlyAfterSet() {
        repository.refreshIfNoCacheClosure = {
            Single.just(RefreshResult.successful)
        }

        XCTAssertFalse(repository.mockCalled)

        repository.requirements = defaultRequirements
        _ = try! repository.refreshIfNoCache()

        XCTAssertTrue(repository.mockCalled)
    }

    func test_refreshIfNoCache_expectCalledOnlyAfterSet() {
        repository.requirements = defaultRequirements
        repository.refreshIfNoCacheClosure = {
            Single.just(RefreshResult.successful)
        }

        XCTAssertFalse(repository.refreshIfNoCacheCalled)

        _ = try! repository.refreshIfNoCache()

        XCTAssertTrue(repository.refreshIfNoCacheCalled)

        _ = try! repository.refreshIfNoCache()

        XCTAssertTrue(repository.refreshIfNoCacheCalled)
    }

    func test_refreshIfNoCache_expectCalledCountIncrementAfterSet() {
        repository.requirements = defaultRequirements
        repository.refreshIfNoCacheClosure = {
            Single.just(RefreshResult.successful)
        }

        XCTAssertEqual(repository.refreshIfNoCacheCallsCount, 0)

        _ = try! repository.refreshIfNoCache()

        XCTAssertEqual(repository.refreshIfNoCacheCallsCount, 1)

        _ = try! repository.refreshIfNoCache()

        XCTAssertEqual(repository.refreshIfNoCacheCallsCount, 2)
    }

    func test_refreshIfNoCache_expectReturnsFromClosure() {
        repository.requirements = defaultRequirements
        var givenInvocations: [RefreshResult] = [
            RefreshResult.successful,
            RefreshResult.skipped(reason: .cancelled)
        ]
        let expectedInvocations = givenInvocations

        repository.refreshIfNoCacheClosure = {
            Single.just(givenInvocations.removeFirst())
        }

        let actualFirstResult = try! repository.refreshIfNoCache().toBlocking().first()!

        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = try! repository.refreshIfNoCache().toBlocking().first()!

        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }

    func test_refreshIfNoCache_givenNoRequirements_expectThrows() {
        XCTAssertThrowsError(_ = try repository.refreshIfNoCache().toBlocking().first())
    }

    // MARK: - observe

    func test_observe_expectMockOnlyAfterSet() {
        repository.observeClosure = {
            Observable.just(CacheState.testing.noCache(requirements: self.defaultRequirements))
        }

        XCTAssertFalse(repository.mockCalled)

        _ = repository.observe()

        XCTAssertTrue(repository.mockCalled)
    }

    func test_observe_expectCalledOnlyAfterSet() {
        repository.observeClosure = {
            Observable.just(CacheState.testing.noCache(requirements: self.defaultRequirements))
        }

        XCTAssertFalse(repository.observeCalled)

        _ = repository.observe()

        XCTAssertTrue(repository.observeCalled)

        _ = repository.observe()

        XCTAssertTrue(repository.observeCalled)
    }

    func test_observe_expectCalledCountIncrementAfterSet() {
        repository.observeClosure = {
            Observable.just(CacheState.testing.noCache(requirements: self.defaultRequirements))
        }

        XCTAssertEqual(repository.observeCallsCount, 0)

        _ = repository.observe()

        XCTAssertEqual(repository.observeCallsCount, 1)

        _ = repository.observe()

        XCTAssertEqual(repository.observeCallsCount, 2)
    }

    func test_observe_expectReturnsFromClosure() {
        var givenInvocations: [CacheState<ReposRepositoryDataSource.Cache>] = [
            CacheState.testing.noCache(requirements: ReposRepositoryDataSource.Requirements(username: "")),
            CacheState.testing.cache(requirements: ReposRepositoryDataSource.Requirements(username: ""), lastTimeFetched: Date())
        ]
        let expectedInvocations = givenInvocations

        repository.observeClosure = {
            Observable.just(givenInvocations.removeFirst())
        }

        let actualFirstResult = try! repository.observe().toBlocking().first()!

        XCTAssertEqual(actualFirstResult, expectedInvocations[0])

        let actualSecondResult = try! repository.observe().toBlocking().first()!

        XCTAssertEqual(actualSecondResult, expectedInvocations[1])
    }
}
