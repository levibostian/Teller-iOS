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
     Repository does what it needs in order to fetch fresh cacheData. Probably call network API.
     
     Feel free to call this function yourself anytime that you want to perform an API call *without* affecting the `OnlineRepository`.
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
     Get existing cached cacheData saved to the device if it exists. If no data exists, return an empty data set. **Do not** return nil or an Observable with nil as a value.
     
     This function will be always executed on a background thread.
     
     This function is only called after data has been fetched successfully. Assume that data is empty (no cache data) or there is cache data.
     */
    func observeCachedData(requirements: GetDataRequirements) -> Observable<Cache>
    
    /**
     * DataType determines if cacheData is empty or not. Because cacheData can be of `Any` type, the DataType must determine when cacheData is empty or not.
     */
    func isDataEmpty(_ cache: Cache) -> Bool

}
