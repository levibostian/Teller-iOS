import Foundation
import Moya
import RxSwift
import Teller

class ReposRepositoryRequirements: RepositoryRequirements {
    /**
     The tag is to make each instance of RepositoryRequirements unique. The tag is used to determine how old cached data is to determine if fresh data needs to be fetched or not. If the tag matches previoiusly cached data of the same tag, the data that data was fetched will be queried and determined if it's considered too old and will fetch fresh data or not from the result of the compare.

     The best practice is to describe what the cache represents. "Repos for <username>" is a great example.
     */
    var tag: RepositoryRequirements.Tag {
        return "Repos for \(username)"
    }

    let username: String

    init(username: String) {
        self.username = username
    }
}

// Struct used to represent the JSON data pulled from the GitHub API.
struct Repo: Codable, Equatable {
    var id: Int!
    var name: String!
}

class ReposRepositoryDataSource: RepositoryDataSource {
    typealias Cache = [Repo]
    typealias Requirements = ReposRepositoryRequirements
    typealias FetchResult = [Repo]
    typealias FetchError = Error

    var maxAgeOfCache: Period = Period(unit: 5, component: .hour)

    // override default value.
    var automaticallyRefresh: Bool {
        return false
    }

    func fetchFreshCache(requirements: ReposRepositoryRequirements) -> Single<FetchResponse<[Repo], FetchError>> {
        // Return network call that returns a RxSwift Single.
        // The project Moya (https://github.com/moya/moya) is my favorite library to do this.

        return MoyaProvider<GitHubService>().rx.request(.listRepos(user: requirements.username))
            .map { (response) -> FetchResponse<[Repo], FetchError> in
                let repos = try! JSONDecoder().decode([Repo].self, from: response.data)

                // If there was a failure, use FetchResponse.failure(Error) and the error will be sent to your user in the UI
                return FetchResponse.success(repos)
            }
    }

    // Note: Teller runs this function from a background thread.
    func saveCache(_ fetchedData: [Repo], requirements: ReposRepositoryRequirements) throws {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
        // If there is an error, you may throw it, and have it get passed to the observer of the Repository.
    }

    // Note: Teller runs this function from the UI thread
    func observeCache(requirements: ReposRepositoryRequirements) -> Observable<[Repo]> {
        // Return Observable that is observing the cached data.
        //
        // When any of the repos in the database have been changed, we want to trigger an Observable update.
        // Teller may call `observeCachedData` regularly to keep data fresh.

        return Observable.just([])
    }

    // Note: Teller runs this function from the same thread as `observeCachedData()`
    func isCacheEmpty(_ cache: [Repo], requirements: ReposRepositoryRequirements) -> Bool {
        return cache.isEmpty
    }
}

class ExampleUsingRepository {
    func observe() {
        let disposeBag = DisposeBag()
        let repository = TellerRepository(dataSource: ReposRepositoryDataSource())

        let reposGetDataRequirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")
        repository.requirements = reposGetDataRequirements
        repository
            .observe()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { (dataState: DataState<[Repo]>) in
                switch dataState.state() {
                case .none: break
                // It is currently undetermined if there is a cache or not. This usually happens when switching requirements in a Repository.
                case .noCache(let fetching, let errorDuringFetch):
                    // Repos have never been fetched before for the GitHub user.
                    break
                case .cache(let cache, let lastFetched, let firstCache, let fetching, let successfulFetch, let errorDuringFetch):
                    // Repos have been fetched before for the GitHub user.
                    // If `cache` is nil, the cache is empty.
                    break
                }

                switch dataState.fetchingState() {
                case .fetching(let fetching, let noCache, let errorDuringFetch, let successfulFetch):
                    // A new cache could be fetching, just completed fetching, or is not fetching at all.
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    func refreshIfNoCache() {
        let disposeBag = DisposeBag()
        let repository = TellerRepository(dataSource: ReposRepositoryDataSource())

        let reposGetDataRequirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")
        repository.requirements = reposGetDataRequirements
        try! repository
            .refreshIfNoCache()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { refreshResult in
                if case .successful = refreshResult {
                    // Cache does exist.
                } else {
                    // Cache does not exist. View the error in `refreshResult` to see why the refresh attempt failed.
                }
            })
            .disposed(by: disposeBag)
    }
}
