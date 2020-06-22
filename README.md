[![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![License](https://img.shields.io/cocoapods/l/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![Platform](https://img.shields.io/cocoapods/p/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
![Swift 5.2.x](https://img.shields.io/badge/Swift-5.2.x-orange.svg)

# Teller

Building an iOS app that fetches data from a network? With Teller, you can add a cache to your iOS app in minutes! Faster apps for a better user experience.

![project logo](misc/logo.jpg)

[Read the official announcement of Teller](https://levibostian.com/blog/manage-cached-data-teller/) to learn more about what it does and why to use it.

*Android developer?* Check out the [Android version of Teller](https://github.com/levibostian/Teller-Android/). 

## What is Teller?

Caching the data that your app fetches from a network call can make your app much more enjoyable to use. 

1. Less loading screens. When the user of your app opens the app, they can view the cache without having to sit through a loading screen. 
2. Help your user perform tasks, faster. When your user opens up your app, they want to complete a task within seconds. By using a cache, you can show data to your user faster to allow them to complete tasks. 
3. When you use a cache, you can take advantage of updating your app's data in the background so when your users open up your app again in the future, they will see the most up-to-date data. 

However, adding a cache to your app takes work. You need to...

1. Fetch, save, and query the cache from a network. 
2. Parse the cache to determine what state it is in. 
3. Make sure you do not unnecessary fetches to update the device fetch (to save user battery) but you also don't want to fetch too infrequent or the cache will be out-of-date. 
4. Handle [pagination](https://en.wikipedia.org/wiki/Pagination) for network data that is endless. 

Teller takes care of all of the tasks above except #1 (that part if your job). All you need to do is tell Teller how to fetch, save, and query the device cache and Teller takes care of the rest. 

This allows you to add a cache to your app within minutes without the boilerplate. 

### Are you building an offline-first mobile app?

Teller is designed for developers building offline-first mobile apps. If you are someone looking to build an offline-first mobile app, also be sure to checkout [Wendy](https://github.com/levibostian/wendy-ios) (there is an [Android version too](https://github.com/levibostian/wendy-android)). Wendy is designed to sync your device's cached data with remote storage. Think of it like this: Teller is really good at `GET` calls for your network API, Wendy is really good at `PUT, POST, DELETE` network API calls. Teller *pulls* data, Wendy *pushes* data. These 2 libraries work really nicely together! 

## Why use Teller?

Not only does Teller help you add a cache to your app quickly and easily, Teller also allows you to make your app more transparent to your users. You will easily be able to tell your users...

1. Exactly how old the cache is.
2. If the local cache they are looking at is being updated now (via a network call) or not.
3. If there was a fetch, if there was an error or not.
4. If the cache has ever been fetched successfully before or not.

When you add a cache to your app it is important to be transparent about the cache so the user understands the state of the cache. Teller handles all of this for you. 

There are also some other benefits of Teller:

* Small. The only dependency at this time is RxSwift ([follow this issue as I work to remove this 1 dependency and make it optional](https://github.com/levibostian/Teller-iOS/issues/6)). Teller is made to do 1 job and do it well and that is: caching data retrieved from a network. 
* Built for Swift, by Swift. Teller is written in Swift which means you can expect a nice to use API.
* Not opinionated. Teller does not care where your data is stored or how it is queried. You simply tell Teller when you're done fetching, saving, and querying and Teller takes care of delivering it to the listeners.
* Well tested. Currently running in production apps and includes unit/integration tests around code base. 
* ~~Full documentation~~ (coming soon. In the meantime, this README is all the documentation you need)
* Add a cache to your network calls that use [pagination](https://en.wikipedia.org/wiki/Pagination). 

## Installation

Teller is available through [CocoaPods](https://cocoapods.org/pods/Teller). To install it, simply add the following line to your Podfile:

```ruby
pod 'Teller', '~> version-here'
```

Replace `version-here` with: [![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller) as this is the latest version at this time. 

**Note: Teller is under development.** Even though it is used in production in my own apps, the code base can change at anytime. 

After using Teller for a handful of years now, I have been able to mature the library as time goes on. The API is still considered Alpha as it may encounter drastic changes in the future. 

# Getting started

Teller is designed with 1 goal in mind: Help you add cache support to your app quickly and easily. You help Teller understand where the cache is saved, how to get it, and Teller takes care of the rest. Let's get going. 

*Note: If you're looking to using pagination with Teller, read this getting started guide first and then read [the pagination section](#pagination) to learn how to do that.*

* First, create an implementation of `RepositoryDataSource`. 

Here is an example. 

```swift
import Foundation
import Teller
import RxSwift
import Moya

class ReposRequirements: RepositoryRequirements {
    
    /**
     The tag is used to determine how old your cache is. Teller uses this to determine if a fresh cache needs to be fetched or not. If the tag matches previously cached data of the same tag, the data that data was fetched will be queried and determined if it's considered too old and will fetch fresh data or not from the result of the compare.
     
     The best practice is to describe what the cache represents. "Repos for <username>" is a great example. 
     */
    var tag: ReposRepositoryRequirements.Tag {
        return "Repos for \(username)"
    }
    
    let username: String
    
    init(username: String) {
        self.username = username
    }
}

// Struct used to represent the JSON data pulled from the GitHub API.
struct Repo: Codable {
    var id: Int!
    var name: String!
}

class ReposRepositoryDataSource: RepositoryDataSource {
    
    typealias Cache = [Repo]
    typealias Requirements = ReposRepositoryRequirements
    typealias FetchResult = [Repo]
    typealias FetchError = Error
    
    // How old a cache can be before it's considered old and an automatic refresh should be performed. 
    // Teller tries to reduce the number of network calls performed to save on bandwidth of your user's device. 
    var maxAgeOfCache: Period = Period(unit: 5, component: .hour)
    
    func fetchFreshCache(requirements: Requirements) -> Single<FetchResponse<Cache, FetchError>> {
        // Return network call that returns a RxSwift Single.
        // The project Moya (https://github.com/moya/moya) is my favorite library to do this.
                
        return MoyaProvider<GitHubService>().rx.request(.listRepos(user: requirements.username))
            .map({ (response) -> FetchResponse<[Repo]> in
                let repos = try! JSONDecoder().decode([Repo].self, from: response.data)
                
                // If there was a failure, use FetchResponse.failure(Error) and the error will be sent to your user in the UI
                return FetchResponse.success(data: repos)
            })
    }
    
    // Note: Teller runs this function from a background thread.
    func saveCache(_ fetchedData: Cache, requirements: Requirements) throws {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
        // If there is an error, you may throw it, and have it get passed to the observer of the Repository.
    }
    
    // Note: Teller runs this function from the UI thread
    func observeCache(requirements: Requirements) -> Observable<Cache> {
        // Return Observable that is observing the cached data.
        //
        // When any of the repos in the database have been changed, we want to trigger an Observable update.
        // Teller may call `observeCachedData` regularly to keep data fresh.
        
        return Observable.just([])
    }

    // Note: Teller runs this function from the same thread as `observeCachedData()`
    func isCacheEmpty(_ cache: Cache, requirements: Requirements) -> Bool {
        return cache.isEmpty
    }
    
}
```

* The last step. Observe your cache. Do this with a `TellerRepository` instance.

```swift 
let disposeBag = DisposeBag()
let repository = TellerRepository(dataSource: ReposRepositoryDataSource())

repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")
repository
    .observe()
    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    .subscribeOn(MainScheduler.instance)
    .subscribe(onNext: { (cacheState: CacheState<[Repo]>) in
        // Teller provides a handy way to parse the `CacheState` to understand the state your cache is in. 
        switch cacheState.state {
        // No cache exists. A successful network request has not happened yet. 
        case .noCache:
            // Repos have never been fetched before for the GitHub user.
            break
        case .cache(let cache, let cacheAge):            
            // Repos have been fetched before for the GitHub user.            
            let isCacheEmpty = cache == nil // If `cache` is nil, the cache is empty.
            // Use `cacheAge` in your UI to tell the user how long ago the last successful network request was. 
        }

        // You can inspect a lot more about the state of your cache. 
        cacheState.isRefreshing // If a network request is happening right now to refresh the cache
        cacheState.justFinishedFirstFetch // The first successful network call just finished
        cacheState.refreshError // Get error from network call if there was one during refresh
        // ... and more. Use these properties in the UI of your app to be transparent about your cache!
    })
    .disposed(by: disposeBag)
```

In order for Teller to do it's magic, you need to (1) initialize the `requirements` property and (2) `observe()` the `TellerRepository` instance. This gives Teller the information it needs to begin. If you forget to set `requirements`, nothing will happen when you `observe()`. 

Done! You are using Teller! Continue reading this document to learn about the advanced 

# Pagination 

It's assumed that you have read the [getting started](#getting-started) section. This section will build on top of that. 

Teller does all of the hard work for adding pagination to your app's cache. All you need to do is take what you learned about how to use Teller thus far and add a few more functions. 

* First, create an implementation of `PagingRepositoryDataSource`. This example will build upon the DataSource in the [getting started](#getting-started) section.

```swift
// `PagingRepositoryRequirements` is a special object used to understand how to fetch pages of data from a network. 
// Some APIs you work with might
// ...use a page number, like GitHub: https://developer.github.com/v3/guides/traversing-with-pagination/
// ...use an ID of your last retrieved item, like SoundCloud https://developers.soundcloud.com/docs/api/guide#pagination
// ...use an ID of the first and last retrieved item, like Twitter  https://developer.twitter.com/en/docs/ads/general/guides/pagination
// 
// Whatever your API uses, you put those properties in this object to keep track of what page you are viewing now. 
struct ReposPagingRequirements: PagingRepositoryRequirements {
    let pageNumber: Int

    func nextPage() -> ReposPagingRequirements {
        return ReposPagingRequirements(pageNumber: pageNumber + 1)
    }
}

class ReposRepositoryDataSource: PagingRepositoryDataSource {
    // The data type your cache is. What `observe()` will use. 
    typealias PagingCache = [Repo]
    // `RepositoryRequirements` subclass you're using
    typealias Requirements = ReposRepositoryRequirements
    // `PagingRepositoryRequirements` subclass you're using
    typealias PagingRequirements = ReposPagingRequirements
    // If you're using an API like Twitter or SoundCloud where future network calls depend 
    // data discovered from the previous network call, this field takes care of that. 
    // Use an Int, String, Tuple, Struct, etc for this. 
    // The GitHub API will simply go to the next page number so this field is not used.     
    typealias NextPageRequirements = Void
    // The data type returned from network calls. 
    typealias PagingFetchResult = [Repo]
    // Use a custom Error for network calls in your fetch calls. 
    typealias FetchError = Error

    static let reposPageSize = 50

    // You can use whatever method you wish for performing a HTTP network call. Moya is used in this example. 
    let moyaProvider = MoyaProvider<GitHubService>(plugins: [HttpLoggerMoyaPlugin()])
    let keyValueStorage = UserDefaultsKeyValueStorage(userDefaults: UserDefaults.standard)

    var maxAgeOfCache: Period = Period(unit: 5, component: .hour)

    var currentRepos: [Repo] {
        guard let currentReposData = keyValueStorage.string(forKey: .repos)?.data else {
            return []
        }

        return try! JSONDecoder().decode([Repo].self, from: currentReposData)
    }

    // When you call `goToNextPage()` on your `TellerPagingRepository`, this function is called to get a new `PagingRequirements` for the next network call. 
    func getNextPagePagingRequirements(currentPagingRequirements: PagingRequirements, nextPageRequirements: NextPageRequirements?) -> PagingRequirements {
        return currentPagingRequirements.nextPage()
    }

    // Teller will call this automatically when it needs. You need to delete all of your cache for the given `Requirements`. 
    // Note: Teller runs this function from a background thread.
    func deleteCache(_ requirements: Requirements) {
        keyValueStorage.delete(key: .repos)
    }

    // Teller will call this automatically when it needs. You need to delete all of your cache for the given `Requirements` *except* for the first page of cache.
    // Note: Teller runs this function from a background thread.
    func persistOnlyFirstPage(requirements: ReposRepositoryRequirements) {
        let currentRepos = self.currentRepos
        guard currentRepos.count > ReposRepositoryDataSource.reposPageSize else {
            return
        }

        let firstPageRepos = Array(currentRepos[0...ReposRepositoryDataSource.reposPageSize])

        keyValueStorage.setString((try! JSONEncoder().encode(firstPageRepos)).string!, forKey: .repos)
    }

    // The network call function has changed in the return type that you return. 
    func fetchFreshCache(requirements: ReposRepositoryRequirements, pagingRequirements: PagingRequirements) -> Single<FetchResponse<FetchResult, Error>> {
        // Return network call that returns a RxSwift Single.
        // The project Moya (https://github.com/moya/moya) is my favorite library to do this.
        return moyaProvider.rx.request(.listRepos(user: requirements.username, pageNumber: pagingRequirements.pageNumber))
            .map { (response) -> FetchResponse<FetchResult, FetchError> in
                let repos = try! JSONDecoder().decode([Repo].self, from: response.data)

                let responseHeaders = response.response!.allHeaderFields
                let paginationNext = responseHeaders["link"] as? String ?? responseHeaders["Link"] as! String
                let areMorePagesAvailable = paginationNext.contains("rel=\"next\"")

                // When using pagination, Teller requires your fetch function to return more information regarding the network calls. 
                // You need to determine if there are more pages to fetch, or not. 
                // Also, populate `nextPageRequirements` with whatever you want that will get passed to `getNextPagePagingRequirements` when you call `goToNextPage()`. 
                // 
                // If there was a failure, use FetchResponse.failure(Error) and the error will be sent to your user in the UI
                return FetchResponse.success(PagedFetchResponse(areMorePages: areMorePagesAvailable, nextPageRequirements: nil, fetchResponse: repos))
            }
    }

    // Save the cache. Friendly reminder to *append* the new cache to storage. You don't want to replace the cache you already have as pagination builds on top of each other. 
    // Note: Teller runs this function from a background thread.    
    func saveCache(_ cache: [Repo], requirements: ReposRepositoryRequirements, pagingRequirements: PagingRequirements) throws {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
        // If there is an error, you may throw it, and have it get passed to the observer of the Repository.
        var combinedRepos = currentRepos
        combinedRepos.append(contentsOf: cache)

        keyValueStorage.setString((try! JSONEncoder().encode(combinedRepos)).string!, forKey: .repos)
    }

    // This function has not changed from the getting started guide.     
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

    // This function has not changed from the getting started guide.   
    // Note: Teller runs this function from the same thread as `observeCachedData()`
    func isCacheEmpty(_ cache: [Repo], requirements: ReposRepositoryRequirements, pagingRequirements: ReposPagingRequirements) -> Bool {
        return cache.isEmpty
    }
}
```

* The last step. Observe your cache. Do this with a `TellerPagingRepository` instance.

```swift 
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

            // Access all of the properties you're used to when not using pagination:
            cacheState.isRefreshing
        }
    })
    .disposed(by: disposeBag)

// When the `UITableView` is scrolled down to the bottom, do...
repository.goToNextPage()
// ...and the next page of cache will be fetched!
```

Here are some references for you if you need more help with paging.
* [Determine when `UITableView` is scrolled to the bottom of the list](https://github.com/levibostian/folio) to know when to load the next page of the cache. 
* [How to show a loading view at the bottom of your `UITableView`]() to notify the users of your app that you are loading more data. Use `cache.areMorePages` like shown in this doc to determine when to hide/show this loading view. 

## Keep app data up-to-date

When users open up your app, they want to see fresh data. Not data that is out dated. To do this, it's best to perform background refreshes while your app is in the background. 

Teller provides a simple method to refresh your `TellerRepository`'s cache while in the background. Run this function as often as you wish. Teller will only perform a new fetch for fresh cache is the cache is outdated. 

```swift
let repository = TellerRepository(dataSource: ReposRepositoryDataSource())
repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")

try! repository.refresh(force: false)
        .subscribe()
```

*Note: You can use the [Background app refresh](https://developer.apple.com/documentation/uikit/core_app/managing_your_app_s_life_cycle/preparing_your_app_to_run_in_the_background/updating_your_app_with_background_app_refresh) feature in iOS to run `refresh` on a set of `TellerRepository`s periodically.*

## Perform a refresh only when there is no existing cache

If your app will not function without a cache, use the convenient `refreshIfNoCache()` function to perform a `refresh()` call *only if* a cache does not already exist for that data source. This is great when your app first starts up after fresh install to download a cache to make your app function. 

Call `refreshIfNoCache()` and when the response is `.successful`, you know that a cache exists. `.successful` will be returned *instantly* if a cache already exists or asynchronously after a successful refresh is complete and the cache exists. 

```swift
let repository = TellerRepository(dataSource: ReposRepositoryDataSource())
repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")

try! repository.refreshIfNoCache()
    .subscribe(onSuccess: { (refreshResult) in
        if case .successful = refreshResult {
            // Cache does exist.
        } else {
            // Cache does not exist. View the error in `refreshResult` to see why the refresh attempt failed.
        }
    })
```

*Note: A cache existing does not determine if a cache is empty or not. A cache exists if it has been successfully fetched at least 1 time before.*

## Manual refresh of cache

Do you have a `UITableView` with pull-to-refresh enabled? Do you have a refresh button in your `UINavigationBar` that you want your users to refresh the data when it's pressed? 

No problem. Tell your Teller `TellerRepository` instance to *force* refresh:

```swift
let repository = TellerRepository(dataSource: ReposRepositoryDataSource())
repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")

repository.refresh(force: true)
        .subscribe()
```

## Convert cache type

If you ever find yourself with an instance of `CacheState<A>` and you want to convert it to type `CacheState<B>`, this is what you do:

```swift
repository.observe()
.map { (dataState) -> CacheState<B> in
    dataState.convert { (a) -> B? in
        guard let a = a else { return nil }
        B(a: a)
    }
}
```

Pretty simple. When you `observe()` a `TellerRepository`, call `convert()` on the instance of `DataState` to change to a different cache type. 

## Enable and disable automatic refresh feature 

One of Teller's conveniences is that it performs `TellerRepository.refresh(force: false)` (notice the automatic refresh is *not* forced to respect the `maxAgeOfCache` to keep network calls to a minimum) calls for you periodically in times such as (1) when new requirements is set on an instance of `RepositoryDataSource`, (2) `TellerRepository.observe()` is called, or (3) a cache update is triggered from the `RepositoryDataSource`. This is convenient as it helps keep the cache always up-to-date.

Because this is convenient, Teller enabled this functionality by default. However, if you wish to disable this feature, you can do so in your `RepositoryDataSource`:

```swift
class ReposRepositoryDataSource: RepositoryDataSource {
    // override default value.
    var automaticallyRefresh: Bool {
        return false
    }
}
```

It's recommended to keep the default functionality of enabling this feature. However, sometimes you may need control of how often network calls are performed. These scenarios are the scenarios when you would disable this feature. 

*Note: It's your responsibility to keep your `RepositoryDataSource`'s cache up-to-date by manually calling `TellerRepository.refresh()` periodically in your app if you decide to disable this automatic refresh feature.*

# Testing 

Teller was built with unit/integration/UI testing in mind. Here is how to use Teller in your tests:

## Write unit tests against `RepositoryDataSource` or `PagingRepositoryDataSource` implementations

Your implementations of `RepositoryDataSource` or `PagingRepositoryDataSource` should be no problem. `RepositoryDataSource` and `PagingRepositoryDataSource` are just protocols. You can unit test your implementation using dependency injection, for example, to test all of the functions of `RepositoryDataSource` or `PagingRepositoryDataSource`. 

## Write unit tests for code that depends on `TellerRepository` or `TellerPagingRepository`

For your app's code that uses the Teller `TellerRepository` or `TellerPagingRepository` class, use the pre-built `TellerRepositoryMock` or `TellerPagingRepositoryMock` for your unit tests. Inject the mock into your class under test using dependency injection. 

Here is an example XCTest for unit testing a class that depends on Teller's `TellerRepository` (use the same concept below for working with `TellerPagingRepository` except use `TellerPagingRepositoryMock`). 

```swift
import RxBlocking
import RxSwift
@testable import YourApp
import XCTest

class RepositoryViewModelTest: XCTestCase {
    var viewModel: ReposViewModel!
    var repository: RepositoryMock<ReposRepositoryDataSource>!

    override func setUp() {
        // Create an instance of `RepositoryMock`
        repository = TellerRepositoryMock(dataSource: ReposRepositoryDataSource())
        // Provide the repository mock to your code under test with dependency injection
        viewModel = ReposViewModel(reposRepository: repository)
    }
    
    func test_observeRepos_givenReposRepositoryObserve_expectReceiveCacheFromReposRepository() {
        // 1. Setup the mock
        let given: CacheState<[Repo]> = DataState.testing.cache(requirements: ReposRepositoryDataSource.Requirements(username: "username"), lastTimeFetched: Date()) {
            $0.cache([
                Repo(id: 1, name: "repo-name")
            ])
        }
        repository.observeClosure = {
            return Observable.just(given)
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

}
```

## Write integration tests around Teller 

Integration tests are a great way to make sure that many moving pieces of your code are working together correctly. Teller provides easy ways for you to write integration tests in your app that uses Teller. 

The idea behind testing with Teller is to give Teller a pre-defined state to be in. Maybe you need to write an integration test for when the app starts up for the first time. Maybe you need to write a test where a cache already exists that Teller fetched. Let's get into how we do this in our tests. 

1. Always clear Teller in the `setup()` test function:

```swift
import XCTest
import Teller 

class YourIntegrationTests: XCTestCase {    

    override func setUp() {        
        Teller.shared.clear()
    }
}
```

2. In your test function, give Teller an initial state:

```swift
import XCTest
import Teller 

class YourIntegrationTests: XCTestCase {    
    private var dataSource: RepositoryDataSource<String, RepositoryRequirements, String>!
    private var repository: TellerRepository<RepositoryDataSource<String, RepositoryRequirements, String>>!

    override func setUp() {
        dataSource = RepositoryDataSource()
        repository = TellerRepository(dataSource: dataSource)
        
        Teller.shared.clear()
    }

    func test_tellerNoCach() {                
        let requirements = RepositoryDataSource.Requirements(username: "")
        
        _ = TellerRepository.testing.initState(repository: repository, requirements: requirements) {
            $0.noCache()
        }     

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `TellerRepository` has never fetched a cache successfully before. 

        // Write the remainder of your integration test function here. 
    }

    func test_tellerCacheEmpty() {                
        let requirements = RepositoryDataSource.Requirements(username: "")
        
        _ = TellerRepository.testing.initState(repository: repository, requirements: requirements) {
            $0.cacheEmpty() {
                $0.cacheTooOld()
            }            
        }     

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `TellerRepository` has fetched a cache successfully, the cache is empty, and the cache is too old which means Teller will attempt to fetch a fresh cache the next time the `TellerRepository` runs.

        // There are other options for `$0.cacheEmpty()` such as:
        //  $0.cacheEmpty() {
        //    $0.cacheNotTooOld()
        //  }         
        // 
        // $0.cacheEmpty() {
        //    $0.lastFetched(Date.yesterday)
        //  }

        // Write the remainder of your integration test function here. 
    }    

    func test_tellerCacheNotEmpty() {
        let requirements = RepositoryDataSource.Requirements(username: "")
        let existingCache = "existing-cache"
        
        _ = TellerRepository.testing.initState(repository: repository, requirements: requirements) {
            $0.cache(existingCache) {
                $0.cacheNotTooOld()
            }
        }     
        // *Note: If your `DataSource.saveCache()` function needs to be executed on a background thread, use `TellerRepository.testing.initStateAsync()` instead of `initState()` shown here. `initSync()` runs the `DataSource.saveCache()` on the thread that you call `initState()` on.*

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `TellerRepository` has fetched a cache successfully, the cache is not empty and contains "existing-cache", and the cache is not too old (the default behavior when a state is not given) which means Teller will not attempt to fetch a fresh cache the next time the `TellerRepository` runs.

        // There are other options for `$0.cache(existingCache)`. They are the same options as $0.cacheEmpty() described above.

        // Write the remainder of your integration test function here. 
    }
}
```

## Example app

However, if you check out the directory: `Example/Teller/` you will see a fully functional iOS app with code snippets you can use to learn about how to use Teller, learn best practices, and compile inside of XCode. 

## Documentation

Documentation is coming shortly. This README is all of the documentation created thus far.

If you read the README and still have questions, please, [create an issue](https://github.com/levibostian/teller-ios/issues/new) with your question. I will respond with an answer and update the README docs to help others in the future. 

## Development 

Teller is a pretty simple CocoaPods XCode workspace. Follow the directions below for the optimal development experience. 

* Install cocoapods/gems and setup workspace:

```bash
$> bundle install
$> cd Example/; pod install; cd ..; 
$> ./hooks/autohook.sh install # installs git hooks 
```

## Author

* Levi Bostian - [GitHub](https://github.com/levibostian), [Twitter](https://twitter.com/levibostian), [Website/blog](http://levibostian.com)

![Levi Bostian image](https://gravatar.com/avatar/22355580305146b21508c74ff6b44bc5?s=250)

## Contribute

Teller is open for pull requests. Check out the [list of issues](https://github.com/levibostian/teller-ios/issues) for tasks I am planning on working on. Check them out if you wish to contribute in that way.

**Want to add features to Teller?** Before you decide to take a bunch of time and add functionality to the library, please, [create an issue]
(https://github.com/levibostian/Teller-iOS/issues/new) stating what you wish to add. This might save you some time in case your purpose does not fit well in the use cases of Teller.

# Where did the name come from?

This library is a powerful Repository. The Repository design pattern is commonly found in the MVVM and MVI patterns. A synonym of repository is *bank*. A *bank teller* is someone who manages your money at a bank and triggers transactions. So, since this library facilitates transactions, teller fits.

# Credits

Header photo by [Tim Evans](https://unsplash.com/photos/Uf-c4u1usFQ?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
