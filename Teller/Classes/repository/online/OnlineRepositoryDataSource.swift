//
//  OnlineRepository.swift
//  Teller
//
//  Created by Levi Bostian on 9/16/18.
//

import Foundation
import RxSwift

public protocol OnlineRepositoryGetDataRequirements {
    typealias Tag = String
    
    var tag: Tag { get }
}

public protocol OnlineRepositoryDataSource {
    associatedtype Cache: Any
    associatedtype GetDataRequirements: OnlineRepositoryGetDataRequirements
    associatedtype FetchResult: Any
    
    var maxAgeOfData: Period { get }
    
    /**
     * Repository does what it needs in order to fetch fresh cacheData. Probably call network API.
     */
    func fetchFreshData(requirements: GetDataRequirements) -> Single<FetchResponse<FetchResult>>
    
    /**
     * Save the cacheData to whatever storage method Repository chooses.
     *
     * It is up to you to call [saveData] when you have new cacheData to save. A good place to do this is in a ViewModel.
     *
     * *Note:* It is up to you to run this function from a background thread. This is not done by default for you.
     */
    func saveData(_ fetchedData: FetchResult)
    
    /**
     * Get existing cached cacheData saved to the device if it exists. Return nil is cacheData does not exist or is empty.
     */
    func observeCachedData(requirements: GetDataRequirements) -> Observable<Cache>
    
    /**
     * DataType determines if cacheData is empty or not. Because cacheData can be of `Any` type, the DataType must determine when cacheData is empty or not.
     */
    func isDataEmpty(_ cache: Cache) -> Bool

}

public extension OnlineRepositoryDataSource {
    
    private func getForceSyncNextTimeFetchKey() -> String {
        return "\(TellerConstants.userDefaultsPrefix)forceSyncNextTimeFetch_\(String(describing: type(of: self)))_key"
    }
    
    func forceSyncNextTimeFetched() {
        TellerConstants.userDefaults.set(true, forKey: getForceSyncNextTimeFetchKey())
    }
    
    func doSyncNextTimeFetched() -> Bool {
        return TellerConstants.userDefaults.bool(forKey: getForceSyncNextTimeFetchKey())
    }
    
    func resetForceSyncNextTimeFetched() {
        TellerConstants.userDefaults.set(false, forKey: getForceSyncNextTimeFetchKey())
    }
    
}
