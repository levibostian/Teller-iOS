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

    func setReposToObserve(username: String) {
        reposRepository.requirements = ReposRepositoryDataSource.Requirements(username: username)
    }
}
