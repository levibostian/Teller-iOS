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
    internal var currentStateOfData: LocalDataStateCompoundBehaviorSubject<DataSource.Cache>? = nil
    internal var currentStateOfDataConnectableObservable: ConnectableObservable<LocalDataState<DataSource.Cache>>? = nil
    internal var currentStateOfDataMulticastDisposable: Disposable? = nil
    
    public var requirements: DataSource.GetDataRequirements? = nil {
        didSet {
            if let requirements = requirements {
                if self.currentStateOfData == nil {
                    let initialStateOfData = LocalDataStateCompoundBehaviorSubject<DataSource.Cache>()
                    let initialValueStateOfData = try! initialStateOfData.subject.value()
                    self.currentStateOfData = initialStateOfData
                    
                    self.currentStateOfDataConnectableObservable = self.currentStateOfData!.subject.multicast { () -> BehaviorSubject<LocalDataState<DataSource.Cache>> in
                        return BehaviorSubject(value: initialValueStateOfData)
                    }
                    self.currentStateOfDataMulticastDisposable = self.currentStateOfDataConnectableObservable!.connect()
                }
                
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
        currentStateOfData?.subject.on(.completed)
        currentStateOfDataMulticastDisposable?.dispose()
        currentStateOfData?.subject.dispose()
        
        observeCacheDisposable?.dispose()
    }
    
    fileprivate func beginObservingCachedData(requirements: DataSource.GetDataRequirements) {
        observeCacheDisposable?.dispose()
        observeCacheDisposable = self.dataSource.observeCachedData()
            .subscribeOn(schedulersProvider.ui)
            .subscribe(onNext: { (cachedData) in
                if (self.dataSource.isDataEmpty(data: cachedData)) {
                    self.currentStateOfData?.onNextEmpty()
                } else {
                    self.currentStateOfData?.onNextData(data: cachedData)
                }
            })
    }
    
    /**
     * Get an observable that gets the current state of data and all future states.
     */
    public final func observe() throws -> Observable<LocalDataState<DataSource.Cache>> {
        guard let _ = self.requirements else {
            throw TellerError.objectPropertiesNotSet(["requirements"])
        }
        
        return currentStateOfDataConnectableObservable!
    }
    
}

