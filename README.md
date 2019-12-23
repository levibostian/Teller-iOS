[![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![License](https://img.shields.io/cocoapods/l/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![Platform](https://img.shields.io/cocoapods/p/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
![Swift 5.0.x](https://img.shields.io/badge/Swift-5.0.x-orange.svg)

# Teller

Building an iOS app that fetches data from a network? With Teller, you can add a cache to your iOS app in minutes! Faster apps for a better user experience.

![project logo](misc/logo.jpg)

[Read the official announcement of Teller](https://levibostian.com/blog/manage-cached-data-teller/) to learn more about what it does and why to use it.

*Android developer?* Check out the [Android version of Teller](https://github.com/levibostian/Teller-Android/). 

## What is Teller?

Caching the data that your app fetches from a network can make your app much more enjoyable to use. 

1. Less loading screens. When the user of your app opens the app, they can view the cache without having to sit through a loading screen. 
2. Help your user perform tasks, faster. When your user opens up your app, they want to complete a task within seconds. By using a cache, you can show data to your user faster to allow them to complete tasks. 
3. When you use a cache, you can take advantage of updating your app's data in the background so when your users open up your app again in the future, they will see the most up-to-date data. 

However, adding a cache to your app takes work. You need to...

1. Fetch, save, and query the cache from a network. 
2. Parse the cache to determine what state it is in. 
3. Make sure you do not unnecessary fetches to update the device fetch (to save user battery) but you also don't want to fetch too infrequent or the cache will be out-of-date. 

Teller takes care of tasks 2 and 3 outlined above. All you need to do is tell Teller how to fetch, save, and query the device cache and Teller takes care of the rest. 

This allows you to add a cache to your app within minutes without the boilerplate. 

## Why use Teller?

Not only does Teller help you add a cache to your app quickly and easily, Teller also allows you to make your app more transparent to your users. You will easily be able to tell your users...

1. Exactly how old the cache is
2. If the local cache they are looking at is being updated now (via a network call) or not
3. If there was a fetch, if there was an error or not
4. If the cache has ever been fetched successfully before or not

When you add a cache to your app it is important to be transparent about the cache so the user understands the state of the cache. Teller handles all of this for you. 

There are also some other benefits of Teller:

* Small. The only dependency at this time is RxSwift ([follow this issue as I work to remove this 1 dependency and make it optional](https://github.com/levibostian/Teller-iOS/issues/6)). Teller is made to do 1 job and do it well and that is: caching data retrieved from a network. 
* Built for Swift, by Swift. Teller is written in Swift which means you can expect a nice to use API.
* Not opinionated. Teller does not care where your data is stored or how it is queried. You simply tell Teller when you're done fetching, saving, and querying and Teller takes care of delivering it to the listeners.
* Well tested. Currently running in production apps and includes unit/integration tests around code base. 
* ~~Full documentation~~ (coming soon. In the meantime, this README is all the documentation you need)

## Installation

Teller is available through [CocoaPods](https://cocoapods.org/pods/Teller). To install it, simply add the following line to your Podfile:

```ruby
pod 'Teller', '~> version-here'
```

Replace `version-here` with: [![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller) as this is the latest version at this time. 

**Note: Teller is under development.** Even though it is used in production in my own apps, the code base can change at anytime. 

After using Teller for a handful of years now, I have been able to mature the library as time goes on. The API is still considered Alpha as it may encounter drastic changes in the future. However, I do not forsee major changes at this time. 

TODO

- [ ] Create example app on how to use it.
- [ ] Make non-RxSwift version of the library to make it even smaller and more portable.
- [ ] Split up the testing utilities into a separate module. 
- [ ] Documentation in form of Jazzy Apple Doc created.

# Getting started

Teller is designed with 1 goal in mind: Help you add cache support to your app quickly and easily. You help Teller understand where the cache is saved, how to get it, and Teller takes care of the rest. Let's get going. 

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
    
    var maxAgeOfCache: Period = Period(unit: 5, component: .hour)
    
    func fetchFreshCache(requirements: ReposRepositoryRequirements) -> Single<FetchResponse<[Repo]>> {
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
```

* The last step. Observe your cache. Do this with a `Repository` instance.

```swift 
let disposeBag = DisposeBag()
let repository: Repository = Repository(dataSource: ReposRepositoryDataSource())

repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")
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
```

Done! You are using Teller!

In order for Teller to do it's magic, you need to (1) initialize the `requirements` property and (2) `observe()` the `Repository` instance. This gives Teller the information it needs to begin. 

Enjoy!

## Keep app data up-to-date

When users open up your app, they want to see fresh data. Not data that is out dated. To do this, it's best to perform background refreshes while your app is in the background. 

Teller provides a simple method to refresh your `Repository`'s cache while in the background. Run this function as often as you wish. Teller will only perform a new fetch for fresh cache is the cache is outdated. 

```swift
let repository: Repository = Repository(dataSource: ReposRepositoryDataSource())
repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")

repository.refresh(force: false)
        .subscribe()
```

*Note: You can use the [Background app refresh](https://developer.apple.com/documentation/uikit/core_app/managing_your_app_s_life_cycle/preparing_your_app_to_run_in_the_background/updating_your_app_with_background_app_refresh) feature in iOS to run `refresh` on a set of `Repository`s periodically.*

## Manual refresh of cache

Do you have a `UITableView` with pull-to-refresh enabled? Do you have a refresh button in your `UINavigationBar` that you want your users to refresh the data when it's pressed? 

No problem. Tell your Teller `Repository` instance to force refresh:

```swift
let repository: Repository = Repository(dataSource: ReposRepositoryDataSource())
repository.requirements = ReposRepositoryDataSource.Requirements(username: "username to get repos for")

repository.refresh(force: true)
        .subscribe()
```

## Convert cache type

If you ever find yourself with an instance of `DataState<A>` and you want to convert it to type `DataState<B>`, this is what you do:

```swift
repository.observe()
.map { (dataState) -> DataState<B> in
    dataState.convert { (a) -> B? in
        guard let a = a else { return nil }
        B(a: a)
    }
}
```

Pretty simple. When you `observe()` a `Repository`, call `convert()` on the instance of `DataState` to change to a different cache type. 

# Testing 

Teller was built with unit/integration/UI testing in mind. Here is how to use Teller in your tests:

## Write unit tests against `RepositoryDataSource` implementations

Your implementations of `RepositoryDataSource` should be no problem. `RepositoryDataSource` is just a protocol. You can unit test your implementation using dependency injection, for example, to test all of the functions of `RepositoryDataSource`. 

## Write unit tests for code that depends on `Repository`

For your app's code that uses the Teller `Repository` class, use the pre-built `Repository` mock for your unit tests. Inject the mock into your class under test using dependency injection. 

Here is an example XCTest for unit testing a class that depends on Teller's `Repository`. 

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
        repository = RepositoryMock(dataSource: ReposRepositoryDataSource())
        // Provide the repository mock to your code under test with dependency injection
        viewModel = ReposViewModel(reposRepository: repository)
    }
    
    func test_observeRepos_givenReposRepositoryObserve_expectReceiveCacheFromReposRepository() {
        // 1. Setup the mock
        let given: DataState<[Repo]> = DataState.testing.cache(requirements: ReposRepositoryDataSource.Requirements(username: "username"), lastTimeFetched: Date()) {
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
    private var repository: Repository<RepositoryDataSource<String, RepositoryRequirements, String>>!

    override func setUp() {
        dataSource = RepositoryDataSource()
        repository = Repository(dataSource: dataSource)
        
        Teller.shared.clear()
    }

    func test_tellerNoCach() {                
        let requirements = RepositoryDataSource.Requirements(username: "")
        
        _ = Repository.testing.initState(repository: repository, requirements: requirements) {
            $0.noCache()
        }     

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `Repository` has never fetched a cache successfully before. 

        // Write the remainder of your integration test function here. 
    }

    func test_tellerCacheEmpty() {                
        let requirements = RepositoryDataSource.Requirements(username: "")
        
        _ = Repository.testing.initState(repository: repository, requirements: requirements) {
            $0.cacheEmpty() {
                $0.cacheTooOld()
            }            
        }     

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `Repository` has fetched a cache successfully, the cache is empty, and the cache is too old which means Teller will attempt to fetch a fresh cache the next time the `Repository` runs.

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
        
        _ = Repository.testing.initState(repository: repository, requirements: requirements) {
            $0.cache(existingCache) {
                $0.cacheNotTooOld()
            }
        }     
        // *Note: If your `DataSource.saveCache()` function needs to be executed on a background thread, use `Repository.testing.initStateAsync()` instead of `initState()` shown here. `initSync()` runs the `DataSource.saveCache()` on the thread that you call `initState()` on.*

        // Teller is all setup! When your app's code uses the `repository`, it will behave just like the `Repository` has fetched a cache successfully, the cache is not empty and contains "existing-cache", and the cache is not too old (the default behavior when a state is not given) which means Teller will not attempt to fetch a fresh cache the next time the `Repository` runs.

        // There are other options for `$0.cache(existingCache)`. They are the same options as $0.cacheEmpty() described above.

        // Write the remainder of your integration test function here. 
    }
}
```

## Example app

This library does *not* yet have a fully functional example iOS app created (yet). However, if you check out the directory: `Example/Teller/` you will see example code snippets that you can use to learn about how to use Teller, learn best practices, and compile inside of XCode. 

## Documentation

Documentation is coming shortly. This README is all of the documentation created thus far.

If you read the README and still have questions, please, [create an issue](https://github.com/levibostian/teller-ios/issues/new) with your question. I will respond with an answer and update the README docs to help others in the future. 

## Are you building an offline-first mobile app?

Teller is designed for developers building offline-first mobile apps. If you are someone looking to build an offline-first mobile app, also be sure to checkout [Wendy-iOS](https://github.com/levibostian/wendy-ios) (there is an [Android version too](https://github.com/levibostian/wendy-android)). Wendy is designed to sync your device's cached data with remote storage. Think of it like this: Teller is really good at `GET` calls for your network API, Wendy is really good at `PUT, POST, DELETE` network API calls. Teller *pulls* data, Wendy *pushes* data. These 2 libraries work really nicely together! 

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
