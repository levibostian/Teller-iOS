import Foundation
import RxSwift
import Teller

class ReposViewModel {
    private let reposRepository: TellerPagingRepository<ReposRepositoryDataSource>

    init(repository: TellerPagingRepository<ReposRepositoryDataSource> = TellerPagingRepository(dataSource: ReposRepositoryDataSource(), firstPageRequirements: ReposRepositoryDataSource.PagingRequirements(pageNumber: 1))) {
        self.reposRepository = repository
    }

    func observeRepos() -> Observable<CacheState<ReposRepositoryDataSource.Cache>> {
        return reposRepository.observe()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    func assertReposCacheExists() -> Single<RefreshResult> {
        return try! reposRepository.refreshIfNoCache()
    }

    /**
     Exists to demonstrate DataState.convert()
     */
    func observeRepoNames() -> Observable<PagedCacheState<[String]>> {
        return reposRepository.observe()
            .map { (cacheState) -> PagedCacheState<[String]> in
                cacheState.convert { (repos) -> [String]? in
                    repos?.map { (repo) -> String in
                        repo.name
                    }
                }
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
    }

    func gotoNextPageOfRepos() {
        reposRepository.goToNextPage()
    }

    func setReposToObserve(username: String) {
        reposRepository.requirements = ReposRepositoryDataSource.Requirements(username: username)
    }

    // Note: Make sure to only call this after `setReposToObserve()`. This won't be a problem if you only add the fresh UI elements when the list is repos is populated.
    func refreshRepos() -> Single<RefreshResult> {
        return try! reposRepository.refresh(force: true)
            .observeOn(MainScheduler.instance)
    }
}
