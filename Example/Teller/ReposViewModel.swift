import Foundation
import RxSwift
import Teller

class ReposViewModel {
    private let reposRepository: Repository<ReposRepositoryDataSource>

    init(reposRepository: Repository<ReposRepositoryDataSource>) {
        self.reposRepository = reposRepository
    }

    func observeRepos() -> Observable<DataState<ReposRepositoryDataSource.Cache>> {
        return reposRepository.observe()
            .observeOn(MainScheduler.instance)
    }

    func observeRepoNames() -> Observable<DataState<[String]>> {
        return reposRepository.observe()
            .map { (dataState) -> DataState<[String]> in
                dataState.convert { (repos) -> [String]? in
                    repos?.map { (repo) -> String in
                        repo.name
                    }
                }
            }
            .observeOn(MainScheduler.instance)
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
