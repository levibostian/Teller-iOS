import RxBlocking
import RxSwift
@testable import Teller
import XCTest

class RepositoryViewModelTest: XCTestCase {
    var viewModel: ReposViewModel!
    var repository: TellerPagingRepositoryMock<ReposRepositoryDataSource>!

    override func setUp() {
        // Create an instance of `RepositoryMock`
        repository = TellerPagingRepositoryMock(dataSource: ReposRepositoryDataSource(), firstPageRequirements: ReposRepositoryDataSource.PagingRequirements(pageNumber: 1))
        // Provide the repository mock to your code under test with dependency injection
        viewModel = ReposViewModel(repository: repository)
    }

    func test_observeRepos_givenReposRepositoryObserve_expectReceiveCacheFromReposRepository() {
        // 1. Setup the mock
        let given: CacheState<PagedCache<[Repo]>> = CacheState.testing.cache(requirements: ReposRepositoryDataSource.Requirements(username: "username"), lastTimeFetched: Date()) {
            $0.cache(PagedCache(areMorePages: false, cache: [
                Repo(id: 1, name: "repo-name")
            ]))
        }
        repository.observeClosure = {
            Observable.just(given)
        }

        // 2. Run the code under test
        let actual = try! repository.observe().toBlocking().first()

        // 3. Assert your code under test is working
        XCTAssertEqual(given, actual)
    }

    func test_setReposToObserve_givenUsername_expectSetRepositoryRequirements() {
        let given = "random-username"

        // Run your code under test
        viewModel.setReposToObserve(username: given)

        // Pull out the properties of the repository mock to see if your code under test works as expected
        XCTAssertTrue(repository.requirementsCalled)
        XCTAssertEqual(repository.requirementsCallsCount, 1)
        let actual = repository.requirementsInvocations[0]!.username
        XCTAssertEqual(given, actual)
    }

    func test_refreshRepos_expectGetResultFromRefresh() {
        viewModel.setReposToObserve(username: "username")
        let expectedResult = RefreshResult.successful

        repository.refreshClosure = { _ in
            Single.just(expectedResult)
        }

        let actualResult = try! viewModel.refreshRepos().toBlocking().first()!

        XCTAssertEqual(expectedResult, actualResult)
    }
}
