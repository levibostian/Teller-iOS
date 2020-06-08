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

struct ReposPagingRequirements: PagingRepositoryRequirements {
    let pageNumber: Int

    func nextPage() -> ReposPagingRequirements {
        return ReposPagingRequirements(pageNumber: pageNumber + 1)
    }
}

// Struct used to represent the JSON data pulled from the GitHub API.
struct Repo: Codable, Equatable {
    var id: Int!
    var name: String!
}

class ReposRepositoryDataSource: PagingRepositoryDataSource {
    typealias PagingCache = [Repo]
    typealias Requirements = ReposRepositoryRequirements
    typealias PagingRequirements = ReposPagingRequirements
    typealias NextPageRequirements = Void
    typealias PagingFetchResult = [Repo]
    typealias FetchError = Error

    static let reposPageSize = 50

    let moyaProvider = MoyaProvider<GitHubService>(plugins: [HttpLoggerMoyaPlugin()])
    let keyValueStorage = UserDefaultsKeyValueStorage(userDefaults: UserDefaults.standard)

    var maxAgeOfCache: Period = Period(unit: 5, component: .hour)

    // override default value.
    var automaticallyRefresh: Bool {
        return true
    }

    var currentRepos: [Repo] {
        guard let currentReposData = keyValueStorage.string(forKey: .repos)?.data else {
            return []
        }

        return try! JSONDecoder().decode([Repo].self, from: currentReposData)
    }

    func getNextPagePagingRequirements(currentPagingRequirements: ReposPagingRequirements, nextPageRequirements: NextPageRequirements?) -> ReposPagingRequirements {
        return currentPagingRequirements.nextPage()
    }

    func deleteCache(_ requirements: ReposRepositoryRequirements) {
        keyValueStorage.delete(key: .repos)
    }

    func persistOnlyFirstPage(requirements: ReposRepositoryRequirements) {
        let currentRepos = self.currentRepos
        guard currentRepos.count > ReposRepositoryDataSource.reposPageSize else {
            return
        }

        let firstPageRepos = Array(currentRepos[0...ReposRepositoryDataSource.reposPageSize])

        keyValueStorage.setString((try! JSONEncoder().encode(firstPageRepos)).string!, forKey: .repos)
    }

    func fetchFreshCache(requirements: ReposRepositoryRequirements, pagingRequirements: PagingRequirements) -> Single<FetchResponse<FetchResult, Error>> {
        // Return network call that returns a RxSwift Single.
        // The project Moya (https://github.com/moya/moya) is my favorite library to do this.
        return moyaProvider.rx.request(.listRepos(user: requirements.username, pageNumber: pagingRequirements.pageNumber))
            .map { (response) -> FetchResponse<FetchResult, FetchError> in
                let repos = try! JSONDecoder().decode([Repo].self, from: response.data)

                let responseHeaders = response.response!.allHeaderFields
                let paginationNext = responseHeaders["link"] as? String ?? responseHeaders["Link"] as! String
                let areMorePagesAvailable = paginationNext.contains("rel=\"next\"")

                // If there was a failure, use FetchResponse.failure(Error) and the error will be sent to your user in the UI
                return FetchResponse.success(PagedFetchResponse(areMorePages: areMorePagesAvailable, nextPageRequirements: Void(), fetchResponse: repos))
            }
    }

    // Note: Teller runs this function from a background thread.
    func saveCache(_ cache: [Repo], requirements: ReposRepositoryRequirements, pagingRequirements: PagingRequirements) throws {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
        // If there is an error, you may throw it, and have it get passed to the observer of the Repository.
        var combinedRepos = currentRepos
        combinedRepos.append(contentsOf: cache)

        keyValueStorage.setString((try! JSONEncoder().encode(combinedRepos)).string!, forKey: .repos)
    }

    // Note: Teller runs this function from the UI thread
    func observeCache(requirements: ReposRepositoryRequirements, pagingRequirements: ReposPagingRequirements) -> Observable<PagingCache> {
        // Return Observable that is observing the cached data.
        //
        // When any of the repos in the database have been changed, we want to trigger an Observable update.
        // Teller may call `observeCachedData` regularly to keep data fresh.

        return keyValueStorage.observeString(forKey: .repos)
            .map { (string) -> PagingCache in
                try! JSONDecoder().decode([Repo].self, from: string.data!)
            }
    }

    // Note: Teller runs this function from the same thread as `observeCachedData()`
    func isCacheEmpty(_ cache: [Repo], requirements: ReposRepositoryRequirements, pagingRequirements: ReposPagingRequirements) -> Bool {
        return cache.isEmpty
    }
}

class ExampleUsingRepository {
    func observe() {
        let disposeBag = DisposeBag()
        let repository = TellerPagingRepository(dataSource: ReposRepositoryDataSource(), firstPageRequirements: ReposRepositoryDataSource.PagingRequirements(pageNumber: 1))

        let reposGetDataRequirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")
        repository.requirements = reposGetDataRequirements
        repository
            .observe()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { (dataState: CacheState<PagedCache<[Repo]>>) in
                switch dataState.state {
                case .noCache:
                    // Repos have never been fetched before for the GitHub user.
                    break
                case .cache(let cache, let cacheAge):
                    // Repos have been fetched before for the GitHub user.
                    // If `cache` is nil, the cache is empty.
                    if let pagedCache = cache {
                        let repositories = pagedCache.cache
                        let areMorePages = pagedCache.areMorePages

                        // Show/hide a "Loading more" footer in your UITableView by `areMorePages` value.
                    } else {
                        // The cache is empty! There are no repos for that particular username.
                        // Display a view in your app that tells the user there are no repositories to show.
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func refreshIfNoCache() {
        let disposeBag = DisposeBag()
        let repository = TellerPagingRepository(dataSource: ReposRepositoryDataSource(), firstPageRequirements: ReposRepositoryDataSource.PagingRequirements(pageNumber: 1))

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
