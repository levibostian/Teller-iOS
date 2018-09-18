//
//  OnlineRepositorySyncRunner.swift
//  Teller
//
//  Created by Levi Bostian on 9/16/18.
//

import Foundation
import RxSwift

/**
 Use in your app: 1 instance per 1 instance of OnlineRepositoryDataSource, to observe a OnlineRepositoryDataSource.
 
 1. Initialize an instance of OnlineRepository
 2. Set the `dataSource` property with an instance of OnlineRepositoryDataSource
 3. Call any of the functions below to sync or observe data.
 */
public class OnlineRepository<DataSource: OnlineRepositoryDataSource> {
    
    private let dataSource: DataSource
    private let syncStateManager: RepositorySyncStateManager
    
    init(dataSource: DataSource, syncStateManager: RepositorySyncStateManager = TellerRepositorySyncStateManager()) {
        self.dataSource = dataSource
        self.syncStateManager = syncStateManager
    }
    
    /**
     * Call if you want to flag the [Repository] to force sync the next time that it needs to sync cacheData.
     */
    public func forceSyncNextTimeFetched() {
        self.dataSource.forceSyncNextTimeFetched()
    }
    
    public func sync(loadDataRequirements: DataSource.GetDataRequirements, force: Bool) -> Single<SyncResult> {
        if (force || self.dataSource.doSyncNextTimeFetched() || self.syncStateManager.isDataTooOld(tag: loadDataRequirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)) {
            return self.dataSource.fetchFreshData(requirements: loadDataRequirements)
                .map({ (fetchResponse: FetchResponse<DataSource.FetchResult>) -> SyncResult in
                    self.dataSource.resetForceSyncNextTimeFetched()
                    
                    if (fetchResponse.isSuccessful()) {
                        self.dataSource.saveData(fetchResponse.data!)
                        self.syncStateManager.updateLastTimeFreshDataFetched(tag: loadDataRequirements.tag)
                            
                        return SyncResult.success()
                    } else {
                        return SyncResult.fail(fetchResponse.failure!)
                    }
                })
        } else {
            return Single.just(SyncResult.skipped(SyncResult.SkippedReason.dataNotTooOld))
        }
    }
    
    /**
     Dev note: You will notice that I am creating a new instance of OnlineDataStateBehaviorSubject every call to this function. At first, I was thinking about sharing 1 instance of OnlineDataStateBehaviorSubject between everyone that calls function. However, I decided to create a new one because of disposing. What if observe() gets called twice, one of those calls then calls dispose() on the Observable? Then that invalidates the other caller of observe(). I don't want to do that. Each Observable instance should be responsible for disposing of it. I am initializing the state of each stateOfData anyway below, so all instances of Observable returned from this function will receive the same events.
     */
    public func observe(loadDataRequirements: DataSource.GetDataRequirements) -> Observable<OnlineDataState<DataSource.Cache>> {
        let stateOfDate: OnlineDataStateBehaviorSubject<DataSource.Cache> = OnlineDataStateBehaviorSubject()
        var observeDisposeBag = CompositeDisposable()
        
        // Note: Only begin observing cached data *after* data has been successfully fetched.
        func initializeObservingCachedData() {
            if (!self.syncStateManager.hasEverFetchedData(tag: loadDataRequirements.tag)) {
                fatalError("You cannot begin observing cached data until after data has been successfully fetched")
            }
            
            observeDisposeBag += self.dataSource.observeCachedData(requirements: loadDataRequirements)
                .subscribe(onNext: { (cache: DataSource.Cache) in
                    let needsToFetchFreshData = self.dataSource.doSyncNextTimeFetched() || self.syncStateManager.isDataTooOld(tag: loadDataRequirements.tag, maxAgeOfData: self.dataSource.maxAgeOfData)
                    
                    if (self.dataSource.isDataEmpty(cache)) {
                        stateOfDate.onNextCacheEmpty(isFetchingFreshData: needsToFetchFreshData)
                    } else {
                        stateOfDate.onNextCachedData(data: cache, dataFetched: self.syncStateManager.lastTimeFetchedData(tag: loadDataRequirements.tag)!, isFetchingFreshData: needsToFetchFreshData)
                    }
                    
                    if (needsToFetchFreshData) {
                        observeDisposeBag += self.sync(loadDataRequirements: loadDataRequirements, force: false)
                            .subscribe(onSuccess: { (syncResult: SyncResult) in
                                stateOfDate.onNextDoneFetchingFreshData(errorDuringFetch: syncResult.failedError)
                            }, onError: { (error) in
                                stateOfDate.onNextDoneFetchingFreshData(errorDuringFetch: error)
                            })
                    }
                })
        }
        
        if (!self.syncStateManager.hasEverFetchedData(tag: loadDataRequirements.tag)) {
            stateOfDate.onNextFirstFetchOfData()
            
            observeDisposeBag += self.sync(loadDataRequirements: loadDataRequirements, force: true)
                .subscribe(onSuccess: { (syncResult: SyncResult) in
                    stateOfDate.onNextDoneFirstFetch(errorDuringFetch: syncResult.failedError)
                    initializeObservingCachedData()
                }) { (error) in
                    stateOfDate.onNextDoneFirstFetch(errorDuringFetch: error)
            }
        } else {
            initializeObservingCachedData()
        }
        
        return stateOfDate.asObservable().do(onDispose: {
            observeDisposeBag.dispose()
        })
    }
    
}
