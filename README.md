[![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![License](https://img.shields.io/cocoapods/l/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
[![Platform](https://img.shields.io/cocoapods/p/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller)
![Swift 4.2.x](https://img.shields.io/badge/Swift-4.2.x-orange.svg)

# Teller

iOS library that manages the state of your app's data. Teller facilitates loading cached data and fetching fresh data so your app's data is always up to date.

Teller works very well with MVVM and MVI design patterns (note the use of `Repository` subclasses in the library). However, you do not need to use these design patterns to use it.

![project logo](misc/logo.jpg)

[Read the official announcement of Teller](https://levibostian.com/blog/manage-cached-data-teller/) to learn more about what it does and why to use it.

*Android developer?* Check out the [Android version of Teller](https://github.com/levibostian/Teller-Android/). 

## What is Teller?

The data used in your mobile app: user profiles, a collection of photos, list of friends, etc. *all have state*. Your data is in 1 of many different states:

* Being fetched for the first time (if it comes from an async network call)
* The data is empty
* Data exists in the device's storage (cached).
* During the empty and data states, your app could also be fetching fresh data to replace the cached data on the device that is out of date.

Determining what state your data is in and managing it can be a big pain. That is where Teller comes in. All you need to do is tell Teller how to save your data, query your data, and how to fetch fresh data (probably with a network API call) and Teller facilities everything else for you. Teller will query your cached data, parse it to determine the state of it, fetch fresh data if the cached data is too old, and deliver the state of the data to listeners so you can update the UI to your users.

## Why use Teller?

When creating mobile apps that cache data (such as offline-first mobile apps), it is important to show in your app's UI the state of your cached data to the app user. Telling your app user how old data is, if your app is performing a network call, if there were any errors during network calls, if the data set is empty or not. These are all states that data can be in and notifying your user of these states helps your user trust your app and feel they are in control.

Well, keeping track of the state of your data can be complex. Querying a database is easy. Performing an network API call is easy. Updating the UI of your app is easy. But tying all of that together can be difficult. That is why Teller was created. You take care of querying data, saving data, fetching fresh data via a network call and let Teller take care of everything else.

For example: If you are building a Twitter client app that is offline-first, when the user opens your app you should be showing them a list of cached tweets so that the user has something to interact with and not a loading screen saying "Loading tweets, please wait...". When you show this list of cached tweets, you may also be performing an API network call in the background to fetch the newest tweets for your user. In the UI of your app, you should be notifying your user that your app is fetching fresh tweets or else your user may think your app is broken. Keeping your user always informed about exactly what your app is doing is a good idea to follow. Teller helps you keep track of the state of your data and facilitates keeping it up to date.

Here are the added benefits of Teller:

* Small. The only dependency at this time is RxSwift ([follow this issue as I work to remove this 1 dependency and make it optional](https://github.com/levibostian/Teller-iOS/issues/6))
* Built for Swift, by Swift. Teller is written in Swift which means you can expect a nice to use API.
* Not opinionated. Teller does not care where your data is stored or how it is queried. You simply tell Teller when you're done fetching, saving, and querying and Teller takes care of delivering it to the listeners.
* Teller works very well with MVVM and MVI design patterns (note the use of `Repository` subclasses in the library). However, you do not need to use these design patterns to use it.

## Installation

Teller is available through [CocoaPods](https://cocoapods.org/pods/Teller). To install it, simply add the following line to your Podfile:

```ruby
pod 'Teller', '~> version-here'
```

Replace `version-here` with: [![Version](https://img.shields.io/cocoapods/v/Teller.svg?style=flat)](https://cocoapods.org/pods/Teller) as this is the latest version at this time. 

**Note: Teller is in early development.** Even though it is used in production in my own apps, it is still early on in development as I use the library more and more, it will mature.

I plan to release the library in an alpha, beta, then stable release phase.

#### Stages:

Alpha (where the library is at currently):

- [ ] Create example app on how to use it.
- [X] Documentation for README created.
- [ ] Make non-RxSwift version of the library to make it even smaller and more portable.
- [ ] Documentation in form of Jazzy Apple Doc created.
- [ ] Documentation on how to use in MVVM, MVI setup and other setups as well.
- [X] Fixup the API for the library if needed.

Beta:

- [ ] Library API has been used enough that the API does not have any huge changes planned for it.
- [X] Tests written (and passing 😉) for the library.

Stable:

- [ ] Library has been running in many production apps, developers have tried it and given feedback on it.

# Getting started

The steps to get Teller up and running is pretty simple: (1) Create a `Repository` subclass for your data set. (2) Add a listener to your `Repository` subclass.

* The first step is where you tell Teller how to query cached data, save data to the cache, and how to fetch fresh data. You do this by creating a subclass of `LocalRepository` or `OnlineRepository`.

What type of `Repository` should you use you ask? Here is a description of each:

...TL;DR...if you need to perform a network call to obtain data, use `OnlineRepository`. Else, `LocalRepository`.

`LocalRepository` is a very simple class that does not use network calls to fetch fresh data. Data is simply saved to a cache and queried. If you need to store data in `UserDefaults`, for example, `LocalRepository` is the perfect way to do that.

`OnlineRepository` is a class that saves data to a cache, queries data from the cache, and performs network calls to fetch fresh data when data expires. If you have a data set that is obtained from calling your network API, use `OnlineRepository`.

Here is an example of each. 

First off, `LocalRepository`:

```swift
import Foundation
import Teller
import RxSwift
import RxCocoa

// Determine what you want to observe locally using the `LocalRepositoryGetDataRequirements`. In this example, we are only going to watch 1 `UserDefaults` key but if you were watching multiple users in 1 app, for example, you could pass in the username of the user to observe and use that username in the `LocalRepositoryDataSource` below. 
struct GitHubUsernameDataSourceGetDataRequirements: LocalRepositoryGetDataRequirements {
}

class GitHubUsernameDataSource: LocalRepositoryDataSource {
    
    typealias Cache = String
    typealias GetDataRequirements = GitHubUsernameDataSourceGetDataRequirements
    
    fileprivate let userDefaultsKey = "githubuserdatasource"
    
    typealias DataType = String
    
    // This function gets called from whatever thread you call it from.    
    func saveData(data: String) {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
    // Note: Teller calls this function from the UI thread. 
    func observeCachedData() -> Observable<String> {
        return UserDefaults.standard.rx.observe(String.self, userDefaultsKey)
            .map({ (value) -> String in return value! })
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
```

This is a `LocalRepository` that is meant to store a `String` representing a GitHub username. As you can see, this `LocalRepository` uses `UserDefaults` to store data. You may use whatever type of data storage that you prefer!

Now onto `OnlineRepository`. Here is an example of that:

```swift
import Foundation
import Teller
import RxSwift
import Moya

class ReposRepositoryGetDataRequirements: OnlineRepositoryGetDataRequirements {
    
    /**
     The tag is to make each instance of OnlineRepositoryGetDataRequirements unique. The tag is used to determine how old cached data is to determine if fresh data needs to be fetched or not. If the tag matches previoiusly cached data of the same tag, the data that data was fetched will be queried and determined if it's considered too old and will fetch fresh data or not from the result of the compare.
     
     The best practice is to use the name of the OnlineRepositoryGetDataRequirements subclass and the value of any variables that are used for fetching fresh data.
     */
    var tag: ReposRepositoryGetDataRequirements.Tag {
        return "ReposRepositoryGetDataRequirements_\(username)"
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

class ReposRepositoryDataSource: OnlineRepositoryDataSource {
    
    typealias Cache = [Repo]
    typealias GetDataRequirements = ReposRepositoryGetDataRequirements
    typealias FetchResult = [Repo]
    
    var maxAgeOfData: Period = Period(unit: 5, component: .hour)
    
    func fetchFreshData(requirements: ReposRepositoryGetDataRequirements) -> Single<FetchResponse<[Repo]>> {
        // Return network call that returns a RxSwift Single.
        // The project Moya (https://github.com/moya/moya) is my favorite library to do this.
        
        let provider = MoyaProvider<GitHubService>()
        return provider.rx.request(.listRepos(user: requirements.username))
            .map({ (response) -> FetchResponse<[Repo]> in
                let repos = try! JSONDecoder().decode([Repo].self, from: response.data)
                
                return FetchResponse.success(data: repos)
            })
    }
    
    // Note: Teller runs this function from a background thread. 
    func saveData(_ fetchedData: [Repo]) {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
    }
    
    // Note: Teller runs this function from the UI thread
    func observeCachedData(requirements: ReposRepositoryGetDataRequirements) -> Observable<[Repo]> {
        // Return Observable that is observing the cached data.
        //
        // When any of the repos in the database have been changed, we want to trigger an Observable update.
        // Teller may call `observeCachedData` regularly to keep data fresh.
        
        return Observable.just([])
    }
    
    func isDataEmpty(_ cache: [Repo]) -> Bool {
        return cache.isEmpty
    }
    
}

class ReposRepository: OnlineRepository<ReposRepositoryDataSource> {
    
    convenience init() {
        self.init(dataSource: ReposRepositoryDataSource())
    }
    
}
```

This `OnlineRepository` subclass is meant to fetch, store, and query a list of GitHub repositories for a given GitHub username. Notice how Teller will even handle errors in your network fetch calls and deliver the errors to the UI of your application for you!

Now it's your turn. Create subclasses of `OnlineRepository` and `LocalRepository` for your data sets!

* The last step. Observe your data set. This is also pretty simple.

`LocalRepository`

```swift
let disposeBag = DisposeBag()
let repository: GitHubUsernameRepository = GitHubUsernameRepository()
repository.requirements = GitHubUsernameDataSourceGetDataRequirements()

repository
    .observe()
    .subscribeOn(MainScheduler.instance)
    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    .subscribe(onNext: { (dataState: LocalDataState<GitHubUsernameDataSource.DataType>) in
        switch dataState.state() {
        case .isEmpty:
            // The GitHub username is empty. It has never been set before.
            break
        case .data(let username):
            // `username` is the GitHub username that has been set last.
            break
        }
    }).disposed(by: disposeBag)

// Now let's say that you want to *update* the GitHub username. On your instance of GitHubUsernameRepository, save data to it. All of your observables will be notified of this change.
repository.dataSource.saveData(data: "new username")
```

`OnlineRepository`

```swift 
let disposeBag = DisposeBag()
let repository: ReposRepository = ReposRepository()

let reposGetDataRequirements = ReposRepositoryDataSource.GetDataRequirements(username: "username to get repos for")
repository.requirements = reposGetDataRequirements
repository
    .observe()
    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    .subscribeOn(MainScheduler.instance)
    .subscribe(onNext: { (dataState: OnlineDataState<[Repo]>) in
        switch dataState.cacheState() {
        case .cacheEmpty?:
            // Cache is empty. Repos for this specific user has been fetched before, but they do not have any for their account.
            break
        case .cacheData(let repos, let dateReposWhereFetched)?:
            // Here are the repos for the user!
            // You can figure out how old the cached data is with `dateReposWhereFetched` as it's a Date.
            break
        case .none:
            // the dataState has no cached state yet. This probably means that repos have never been fetched for this specific username before.
            // Use the `noCacheState` to get more details on the state on not having a cache.
            break
        }
        switch dataState.noCacheState() {
        case .noCache?:
            // Repos have never been fetched before for the specific user. Cache data is not beging fetched at this time.
            break
        case .firstFetchOfData?:
            // Repos have never been fetched before for the specific user. So, this state means that repos are being fetched for the very first time for this user.
            break
        case .finishedFirstFetchOfData(let errorDuringFetch)?:
            // Repos have been fetched for the very first time for this specific user. A `cacheState()` will also be sent to the dataState. This state does *not* mean that the fetch was successful. It simply means that it is done.
            
            // If there was an error that happened during the fetch, errorDuringFetch will be populated.
            
            // Note: If there is an error on first fetch, you can call `observe()` again or `refresh()` on your `OnlineRepository` to try again. It is your responsibility to manually try the first fetch again.
            break
        case .none:
            // The dataState has no first fetch state. This means that repos have been fetched before for this specific user so no first fetch is required.
            break
        }
        switch dataState.fetchingFreshDataState() {
        case .fetchingFreshCacheData?:
            // The cached repos for the specific user is too old and new, fresh data is being fetched right now.
            break
        case .finishedFetchingFreshCacheData(let errorDuringFetch)?:
            // Fresh repos have been fetched for this specific user. This state does *not* mean that the fetch was successful. It simply means that it is done.
            
            // If there was an error that happened during the fetch, errorDuringFetch will be populated.
            break
        case .none:
            // The dataState has no fetch state. This means that the repos cache is not too old or repos have never been fetched before.
            break
        }
    })
    .disposed(by: disposeBag)
```

Done! You are using Teller! When you add a listener to your `Repository` subclass, Teller kicks into gear and begins it's work parsing your cached data and fetching fresh if needed.

Enjoy!

## Extra functionality

Teller comes with extra, but optional, features you may also enjoy.

#### Keep app data fresh in the background

You want to make sure that the data of your app is always up-to-date. When your users open your app, it's nice that they can jump right into some new content and not need to wait for a fetch to complete. Teller provides a simple method to refresh your `Repository`s data with your remote storage.

```swift
let repository: ReposRepository = ReposRepository()        
let reposGetDataRequirements = ReposRepositoryDataSource.GetDataRequirements(username: "username to get repos for")
repository.requirements = reposGetDataRequirements

repository.refresh(force: false)
        .subscribe()
```

Teller `OnlineRepository`s provides a `refresh` function. `refresh` will check if the cached data is too old. If cached data is too old, it will fetch fresh data and save it and if it's not too old, it will simply ignore the request (unless `force` is `true`). `refresh` returns a `Single`, so we need to subscribe to it to run the refresh.

You can use the [Background app refresh](https://developer.apple.com/documentation/uikit/core_app/managing_your_app_s_life_cycle/preparing_your_app_to_run_in_the_background/updating_your_app_with_background_app_refresh) feature in iOS to run `refresh` on a set of `OnlineRepository`s periodically. 

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
$> cd Teller/Example
$> pod install
$> bundle install
```

* Setup git hooks [via overcommit](https://github.com/brigade/overcommit/) to run misc tasks for you when using git. 

```bash
$> overcommit --install
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
