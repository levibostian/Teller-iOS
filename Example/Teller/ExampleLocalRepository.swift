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
import RxCocoa

// Determine what you want to observe locally using the `LocalRepositoryGetDataRequirements`. In this example, we are only going to watch 1 `UserDefaults` key but if you were watching multiple users in 1 app, for example, you could pass in the username of the user to observe and use that username in the `LocalRepositoryDataSource` below.
struct GitHubUsernameDataSourceGetDataRequirements: LocalRepositoryGetDataRequirements {
}

class GitHubUsernameDataSource: LocalRepositoryDataSource {
    
    typealias Cache = String
    typealias GetDataRequirements = GitHubUsernameDataSourceGetDataRequirements
    
    fileprivate let userDefaultsKey = "githubuserdatasource"
    
    typealias DataType = String
    
    func saveData(data: String) {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
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

class ExampleUsingLocalRepository {
    
    func observe() {
        let disposeBag = DisposeBag()
        let repository: GitHubUsernameRepository = GitHubUsernameRepository()
        repository.requirements = GitHubUsernameDataSourceGetDataRequirements()
        
        try! repository
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
    }
    
}
