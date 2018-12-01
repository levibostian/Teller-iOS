//
//  LocalRepository.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation
import RxSwift

open class LocalRepository<DataSource: LocalRepositoryDataSource> {
    
    public let dataSource: DataSource
    internal let schedulersProvider: SchedulersProvider
    
    internal var observeCacheDisposable: Disposable? = nil
    internal var currentStateOfData: LocalDataStateCompoundBehaviorSubject<DataSource.Cache> = LocalDataStateCompoundBehaviorSubject()
    
    public var requirements: DataSource.GetDataRequirements? = nil {
        didSet {
            self.currentStateOfData.resetStateToNone()
            
            if let requirements = requirements {
                beginObservingCachedData(requirements: requirements)
            }
        }
    }
    
    required public init(dataSource: DataSource) {
        self.dataSource = dataSource
        self.schedulersProvider = AppSchedulersProvider()
    }
    
    internal init(dataSource: DataSource, schedulersProvider: SchedulersProvider) {
        self.dataSource = dataSource
        self.schedulersProvider = schedulersProvider
    }
    
    deinit {
        currentStateOfData.subject.on(.completed)
        currentStateOfData.subject.dispose()
        
        observeCacheDisposable?.dispose()
    }
    
    fileprivate func beginObservingCachedData(requirements: DataSource.GetDataRequirements) {
        observeCacheDisposable?.dispose()
        
        observeCacheDisposable = self.dataSource.observeCachedData()
            .subscribeOn(schedulersProvider.ui)
            .subscribe(onNext: { [unowned self] (cachedData) in
                if (self.dataSource.isDataEmpty(data: cachedData)) {
                    self.currentStateOfData.onNextEmpty()
                } else {
                    self.currentStateOfData.onNextData(data: cachedData)
                }
            })
    }
    
    /**
     * Get an observable that gets the current state of data and all future states.
     */
    public final func observe() -> Observable<LocalDataState<DataSource.Cache>> {
        return currentStateOfData.subject
    }
    
}

