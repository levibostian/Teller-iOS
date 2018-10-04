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

class GitHubUsernameDataSource: LocalRepositoryDataSource {
    
    fileprivate let userDefaultsKey = "githubuserdatasource"
    
    typealias DataType = String
    
    func saveData(data: String) {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
    func observeData() -> Observable<String> {
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
        
        repository
            .observe()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribeOn(MainScheduler.instance)
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
        
        // Now let's say that you want to *update* the GitHub username. Anywhere in your code, you can create an instance of a GitHubUsernameRepository and save data to it. All of your observables will be notified of this change.
        
         repository.dataSource.saveData(data: "new username")
    }
    
}
