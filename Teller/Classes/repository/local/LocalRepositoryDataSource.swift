//
//  LocalRepositoryDataSource.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation
import RxSwift

public protocol LocalRepositoryDataSource {
    associatedtype DataType: Any
    
    /**
     * Save the cacheData to whatever storage method Repository chooses.
     *
     * It is up to you to call [saveData] when you have new cacheData to save. A good place to do this is in a ViewModel.
     *
     * *Note:* It is up to you to run this function from a background thread. This is not done by default for you.
     */
    func saveData(data: DataType)
    
    /**
     * This function should be setup to trigger anytime there is a data change. So if you were to call [saveData], anyone observing the [Observable] returned here will get notified of a new update.
     */
    func observeData() -> Observable<DataType>
    
    /**
     * DataType determines if cacheData is empty or not. Because cacheData can be of `Any` type, the DataType must determine when cacheData is empty or not.
     */
    func isDataEmpty(data: DataType) -> Bool
}
