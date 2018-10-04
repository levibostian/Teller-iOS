//
//  LocalRepository.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation
import RxSwift

open class LocalRepository<DataSource: LocalRepositoryDataSource> {
    
    fileprivate let dataSource: DataSource
    
    required public init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    /**
     * Get an observable that gets the current state of data and all future states.
     */
    public final func observe() -> Observable<LocalDataState<DataSource.DataType>> {
        let stateOfDate: LocalDataStateCompoundBehaviorSubject<DataSource.DataType> = LocalDataStateCompoundBehaviorSubject()
        let observeDisposable: Disposable = dataSource.observeData()
            .subscribe(onNext: { (cachedData) in
                if (self.dataSource.isDataEmpty(data: cachedData)) {
                    stateOfDate.onNextEmpty()
                } else {
                    stateOfDate.onNextData(data: cachedData)
                }
            }, onDisposed: {
            })
        
        return stateOfDate.asObservable().do(onDispose: {
            observeDisposable.dispose()
        })
    }
    
}

