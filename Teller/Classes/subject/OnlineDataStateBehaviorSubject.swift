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
    internal let subject: BehaviorSubject<OnlineDataState<DataType>>
    
    init() {
        let initialDataState = OnlineDataState<DataType>.none()
        self.subject = BehaviorSubject(value: initialDataState)
        self.dataState = initialDataState
    }
    
    /**
     When the `OnlineRepositoryGetDataRequirements` is changed to an `OnlineRepository`, we want to reset to a "none" state where the data has no state. This is just like calling `init()` except we are not re-initializing this whole class. We get to keep the original `subject`.
     */
    func resetStateToNone() {
        self.dataState = OnlineDataState.none()
    }
    
    /**
     * The cacheData is being fetched for the first time.
     */
    func onNextFirstFetchOfData(requirements: OnlineRepositoryGetDataRequirements) {
        dataState = OnlineDataState.firstFetchOfData(requirements: requirements)
    }    
    
    /**
     * The status of cacheData is empty (optionally fetching new fresh cacheData as well).
     */
    func onNextCacheEmpty(requirements: OnlineRepositoryGetDataRequirements, isFetchingFreshData: Bool, dataFetched: Date) {
        dataState = OnlineDataState.isEmpty(requirements: requirements, dataFetched: dataFetched)
        if (isFetchingFreshData) {
            onNextFetchingFreshData()
        }
    }
    
    /**
     * The status of cacheData is cacheData (optionally fetching new fresh cacheData as well).
     */
    func onNextCachedData(requirements: OnlineRepositoryGetDataRequirements, data: DataType, dataFetched: Date, isFetchingFreshData: Bool) {
        dataState = OnlineDataState.data(data: data, dataFetched: dataFetched, requirements: requirements)
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
    
}
