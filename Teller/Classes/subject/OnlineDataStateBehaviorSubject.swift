//
//  OnlineDataStateBehaviorSubject.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation
import RxSwift

/**
 * A wrapper around [BehaviorSubject] and [StateData] to give a "compound" feature to [StateData] it did not have previously.
 *
 * [BehaviorSubject]s are great in that you can grab the very last value that was passed into it. This is a great type of [Observable] since you can always get the very last value that was emitted. This works great with [StateData] so you can always know the state of cacheData by grabbing it's last value.
 *
 * Maintaining the state of an instance of [StateData] is a pain. [StateData] has a state (loading, empty, cacheData) but it also has some other states built on top of it temporarily such as if an error occurs or if cacheData is currently being fetched. The UI cares about all of these states [StateData] could be in to display the best message to the user as possible. However, when an error occurs, for example, we need to pass the error to [StateData] to be handled by the UI. *Someone at some point needs to handle this error. We don't want it to go ignored*. What if we call [BehaviorSubject.onNext] with an instance of [StateData] with an error in it? That is unsafe. We could call [BehaviorSubject.onNext] shortly after with an instance of [StateData] without an error. **That error has now gone unseen!**
 *
 * Another use case to think about is fetching cacheData. You could call [BehaviorSubject.onNext] with an instance of [StateData] saying cacheData is fetching then shortly after an error occurs, the database fields changed, database rows were deleted, etc. and we will call [BehaviorSubject.onNext] again with another instance of [StateData]. Well, we need to keep track somehow of the fetching status of cacheData. That is a pain to maintain and make sure it is accurate. It's also error prone.
 *
 * With that in mind, we "compound" errors and status of fetching cacheData to the last instance of [StateData] found inside of an instance of [BehaviorSubject].
 */

// This class is meant to work with OnlineRepository because it has all the states cacheData can have, including loading and fetching of fresh cacheData.
internal class OnlineDataStateBehaviorSubject<DataType: Any> {
    
    private var dataState: OnlineDataState<DataType>! {
        didSet {
            subject.onNext(dataState)
        }
    }
    private let subject: BehaviorSubject<OnlineDataState<DataType>>
    private let getDataRequirements: OnlineRepositoryGetDataRequirements
    
    init(getDataRequirements: OnlineRepositoryGetDataRequirements) {
        self.getDataRequirements = getDataRequirements
        
        let initialDataState = OnlineDataState<DataType>.none(getDataRequirements: self.getDataRequirements)
        self.subject = BehaviorSubject(value: initialDataState)
        self.dataState = initialDataState
    }
    
    /**
     * The cacheData is being fetched for the first time.
     */
    func onNextFirstFetchOfData() {
        dataState = OnlineDataState.firstFetchOfData(getDataRequirements: self.getDataRequirements)
    }    
    
    /**
     * The status of cacheData is empty (optionally fetching new fresh cacheData as well).
     */
    func onNextCacheEmpty(isFetchingFreshData: Bool, dataFetched: Date) {
        dataState = OnlineDataState.isEmpty(getDataRequirements: self.getDataRequirements, dataFetched: dataFetched)
        if (isFetchingFreshData) {
            onNextFetchingFreshData()
        }
    }
    
    /**
     * The status of cacheData is cacheData (optionally fetching new fresh cacheData as well).
     */
    func onNextCachedData(data: DataType, dataFetched: Date, isFetchingFreshData: Bool) {
        dataState = OnlineDataState.data(data: data, dataFetched: dataFetched, getDataRequirements: self.getDataRequirements)
        if (isFetchingFreshData) {
            onNextFetchingFreshData()
        }
    }
    
    /**
     * Fresh cacheData is being fetched. Compound that status to the existing [StateData] instance.
     */
    func onNextFetchingFreshData() {
        dataState = dataState.fetchingFreshData()
    }
    
    /**
     * Fresh cacheData is done being fetched. Compound that status to the existing [StateData] instance.
     */
    func onNextDoneFetchingFreshData(errorDuringFetch: Error?) {
        dataState = dataState.doneFetchingFreshData(errorDuringFetch: errorDuringFetch)
    }
    
    func onNextDoneFirstFetch(errorDuringFetch: Error?) {
        dataState = dataState.doneFirstFetch(error: errorDuringFetch)
    }
    
    /**
     * Get a [BehaviorSubject] as an [Observable]. Convenient as you more then likely do not need to care about the extra functionality of [BehaviorSubject] when you simply want to observe cacheData changes.
     */
    func asObservable() -> Observable<OnlineDataState<DataType>> {
        return subject
    }
    
}
