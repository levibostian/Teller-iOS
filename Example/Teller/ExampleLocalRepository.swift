import Foundation
import RxCocoa
import RxSwift
import Teller

// Determine what you want to observe locally using the `LocalRepositoryGetDataRequirements`. In this example, we are only going to watch 1 `UserDefaults` key but if you were watching multiple users in 1 app, for example, you could pass in the username of the user to observe and use that username in the `LocalRepositoryDataSource` below.
struct GitHubUsernameDataSourceRequirements: LocalRepositoryGetDataRequirements {}

class GitHubUsernameDataSource: LocalRepositoryDataSource {
    typealias Cache = String
    typealias GetDataRequirements = GitHubUsernameDataSourceRequirements

    fileprivate let userDefaultsKey = "githubuserdatasource"

    typealias DataType = String

    // This function gets called from whatever thread you call it from.
    func saveData(data: String) throws {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }

    // Note: Teller calls this function from the UI thread.
    func observeCachedData() -> Observable<String> {
        return UserDefaults.standard.rx.observe(String.self, userDefaultsKey)
            .map { (value) -> String in value! }
    }

    func isDataEmpty(data: String) -> Bool {
        return data.isEmpty
    }
}

class GitHubUsernameRepository: LocalRepository<GitHubUsernameDataSource> {
    convenience init() {
        self.init(dataSource: GitHubUsernameDataSource())
    }
}

class ExampleUsingLocalRepository {
    func observe() {
        let disposeBag = DisposeBag()
        let repository: GitHubUsernameRepository = GitHubUsernameRepository()
        repository.requirements = GitHubUsernameDataSourceRequirements()

        repository
            .observe()
            .subscribeOn(MainScheduler.instance)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { (dataState: LocalDataState<GitHubUsernameDataSource.DataType>) in
                switch dataState.state() {
                case .isEmpty(let error)?:
                    // The GitHub username is empty. It has never been set before.
                    break
                case .data(let username, let error)?:
                    // `username` is the GitHub username that has been set last.
                    break
                case .none:
                    // There is no state yet. This is probably because you have not yet set the requirements on the repository yet.
                    break
                }
            }).disposed(by: disposeBag)

        // Now let's say that you want to *update* the GitHub username. On your instance of GitHubUsernameRepository, save data to it. All of your observables will be notified of this change.
        repository.newCache("new username")
    }
}
