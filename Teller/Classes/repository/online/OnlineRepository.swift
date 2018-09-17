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
    
    var dataSource: DataSource?
    private let syncStateManager: RepositorySyncStateManager
    
    init(syncStateManager: RepositorySyncStateManager = TellerRepositorySyncStateManager()) {
        self.syncStateManager = syncStateManager
    }
    
    /**
     * Call if you want to flag the [Repository] to force sync the next time that it needs to sync cacheData.
     */
    public func forceSyncNextTimeFetched() {
        let dataSource = assertDataSourceSet()
        
        dataSource.forceSyncNextTimeFetched()
    }
    
    private func assertDataSourceSet() -> DataSource {
        guard let dataSource = self.dataSource else {
            fatalError("You have not yet set the dataSource parameter.")
        }
        return dataSource
    }
    
    public func sync(loadDataRequirements: DataSource.GetDataRequirements, force: Bool) -> Single<SyncResult> {
        let dataSource = assertDataSourceSet()
        
        if (force || dataSource.doSyncNextTimeFetched() || self.syncStateManager.isDataTooOld(tag: loadDataRequirements.tag, maxAgeOfData: dataSource.maxAgeOfData)) {
            return Single.create(subscribe: { (observer) -> Disposable in
                dataSource.fetchFreshData(requirements: loadDataRequirements)
                    .subscribe(onSuccess: { (fetchResponse) in
                        dataSource.resetForceSyncNextTimeFetched()
                        
                        if (fetchResponse.isSuccessful()) {
                            dataSource.saveData(fetchResponse.data!)
                            self.syncStateManager.updateLastTimeFreshDataFetched(tag: loadDataRequirements.tag)
                            
                            observer(SingleEvent.success(SyncResult.success()))
                        } else {
                            observer(SingleEvent.success(SyncResult.fail(fetchResponse.failure!)))
                        }
                    }, onError: { (error) in
                        observer(SingleEvent.error(error))
                    })
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
        let dataSource = assertDataSourceSet()
        var observeDisposeBag = CompositeDisposable()
        
        func initializeObservingCachedData() {
            observeDisposeBag += dataSource.observeCachedData(requirements: loadDataRequirements)
                .subscribe(onNext: { (cache: DataSource.Cache) in
                    let needsToFetchFreshData = dataSource.doSyncNextTimeFetched() || self.syncStateManager.isDataTooOld(tag: loadDataRequirements.tag, maxAgeOfData: dataSource.maxAgeOfData)
                    
                    if (dataSource.isDataEmpty(cache)) {
                        stateOfDate.onNextCacheEmpty(isFetchingFreshData: needsToFetchFreshData)
                    } else {
                        stateOfDate.onNextCachedData(data: cache, dataFetched: self.syncStateManager.lastTimeFetchedData(tag: loadDataRequirements.tag)!, isFetchingFreshData: needsToFetchFreshData)
                    }
                    
                    if (needsToFetchFreshData) {
                        observeDisposeBag += self.sync(loadDataRequirements: loadDataRequirements, force: false)
                            .subscribe(onSuccess: { (syncResult: SyncResult) in
                                stateOfDate.onNextDoneFetchingFreshData(errorDuringFetch: nil)
                            }, onError: { (error) in
                                stateOfDate.onNextDoneFetchingFreshData(errorDuringFetch: error)
                            })
                    }
                })
        }
        
        if (!self.syncStateManager.hasEverFetchedData(tag: loadDataRequirements.tag)) {
            stateOfDate.onNextFirstFetchOfData()
            
            observeDisposeBag += self.sync(loadDataRequirements: loadDataRequirements, force: false)
                .subscribe(onSuccess: { (syncResult: SyncResult) in
                    stateOfDate.onNextDoneFirstFetch(errorDuringFetch: nil)
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
