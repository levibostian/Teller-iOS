import Foundation
import RxSwift

/**
 * A wrapper around [BehaviorSubject] and [StateData] to give a "compound" feature to [StateData] it did not have previously.
 *
 * This class is designed to be thread-safe as anyone using an instance could update the state on multiple different threads.
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
// You may see many `try!` statements in this file. The code based used to have many `fatalError` statements but those are (1) not testable and (2) not flexible with the potential try/catch in the future if we see a potential for that. So, using `try!` allows us to have errors thrown that we can then fix later.
internal class OnlineDataStateBehaviorSubject<DataType: Any> {
    private let dataSourceQueue = DispatchQueue(label: "\(TellerConstants.namespace)_OnlineDataStateBehaviorSubject_dataSourceQueue")
    private var _dataState: OnlineDataState<DataType>! {
        didSet {
            subject.onNext(_dataState)
        }
    }

    private var dataState: OnlineDataState<DataType>! {
        get {
            var dataStateCopy: OnlineDataState<DataType>?
            dataSourceQueue.sync {
                dataStateCopy = self._dataState
            }
            return dataStateCopy!
        }
        set {
            dataSourceQueue.sync {
                self._dataState = newValue
            }
        }
    }

    internal let subject: BehaviorSubject<OnlineDataState<DataType>>

    var currentState: OnlineDataState<DataType> {
        return try! subject.value()
    }

    init() {
        let initialDataState = OnlineDataState<DataType>.none()
        self.subject = BehaviorSubject(value: initialDataState)
        self.dataState = initialDataState
    }

    /**
     When the `OnlineRepositoryGetDataRequirements` is changed in an `OnlineRepository` to nil, we want to reset to a "none" state where the data has no state and there is nothing to keep track of. This is just like calling `init()` except we are not re-initializing this whole class. We get to keep the original `subject`.
     */
    func resetStateToNone() {
        dataState = OnlineDataState.none()
    }

    func resetToNoCacheState(requirements: OnlineRepositoryGetDataRequirements) {
        dataState = OnlineDataStateStateMachine<DataType>.noCacheExists(requirements: requirements)
    }

    func resetToCacheState(requirements: OnlineRepositoryGetDataRequirements, lastTimeFetched: Date) {
        dataState = OnlineDataStateStateMachine<DataType>.cacheExists(requirements: requirements, lastTimeFetched: lastTimeFetched)
    }

    func changeState(_ change: (OnlineDataStateStateMachine<DataType>) -> OnlineDataState<DataType>) {
        dataState = change(dataState.stateMachine!)
    }
}
