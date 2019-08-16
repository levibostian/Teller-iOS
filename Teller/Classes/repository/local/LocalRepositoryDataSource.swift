//
//  LocalRepositoryDataSource.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation
import RxSwift

public protocol LocalRepositoryGetDataRequirements {
}

public protocol LocalRepositoryDataSource {
    associatedtype Cache: Any
    associatedtype GetDataRequirements: LocalRepositoryGetDataRequirements
    
    /**
     * Save the cacheData to whatever storage method Repository chooses.
     *
     * It is up to you to call [saveData] when you have new cacheData to save. A good place to do this is in a ViewModel.
     *
     * *Note:* It is up to you to run this function from a background thread. This is not done by default for you.
     */
    func saveData(data: Cache) throws
    
    /**
     * This function should be setup to trigger anytime there is a data change. So if you were to call [saveData], anyone observing the [Observable] returned here will get notified of a new update.
     
     Note: Teller calls observeCachedData from the UI thread. 
     */
    func observeCachedData() -> Observable<Cache>
    
    /**
     * DataType determines if cacheData is empty or not. Because cacheData can be of `Any` type, the DataType must determine when cacheData is empty or not.
     */
    func isDataEmpty(data: Cache) -> Bool
}
