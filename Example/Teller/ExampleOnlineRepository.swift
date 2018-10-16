//
//  ExampleOnlineRepository.swift
//  Teller_Example
//
//  Created by Levi Bostian on 10/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

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
// ObjectMapper is used here to map the JSON to the struct.
struct Repo: Codable {
    var id: Int!
    var name: String!
}

class ReposRepositoryDataSource: OnlineRepositoryDataSource {
    
    typealias Cache = [Repo]
    typealias GetDataRequirements = ReposRepositoryGetDataRequirements
    typealias FetchResult = [Repo]
    
    fileprivate let cachedDataObservable: PublishSubject<[Repo]> = PublishSubject()
    
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
    
    func saveData(_ fetchedData: [Repo]) {
        // Save data to CoreData, Realm, UserDefaults, File, whatever you wish here.
        
        // Then, we will trigger an update to the observeCachedData subject so that anyone observing that observable can be updated with the new repos.
        cachedDataObservable.on(Event<[Repo]>.next(fetchedData))
    }
    
    func observeCachedData(requirements: ReposRepositoryGetDataRequirements) -> Observable<[Repo]> {
        // Return Observable that is observing the cached data.
        // Anytime that the repos model has been updated, send an update to the Observable.
        
        return cachedDataObservable.asObservable()
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

class ExampleUsingOnlineRepository {
    
    func observe() {
        let disposeBag = DisposeBag()
        let repository: ReposRepository = ReposRepository()
        
        let reposGetDataRequirements = ReposRepositoryDataSource.GetDataRequirements(username: "username to get repos for")
        
        repository
            .observe(loadDataRequirements: reposGetDataRequirements)
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
                    break
                }
                switch dataState.firstFetchState() {
                case .firstFetchOfData?:
                    // Repos have never been fetched before for the specific user. So, this state means that repos are being fetched for the very first time for this user.
                    break
                case .finishedFirstFetchOfData(let errorDuringFetch)?:
                    // Repos have been fetched for the very first time for this specific user. A `cacheState()` will also be sent to the dataState. This state does *not* mean that the fetch was successful. It simply means that it is done.
                    
                    // If there was an error that happened during the fetch, errorDuringFetch will be populated.
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
    }
    
}