import Foundation
import RxSwift

/**
 In testing, you want to run all of your Rx code on the same thread so that it all runs synchronously. So, we need to inject this provider into our code so that when we test our code we can edit the threads to run on and be able to run everything on the same thread.
 */
internal protocol SchedulersProvider {
    var ui: ImmediateSchedulerType { get }
    var background: ImmediateSchedulerType { get }

    func backgroundWithQueue(_ dispatchQueue: DispatchQueue) -> ImmediateSchedulerType
}

internal class AppSchedulersProvider: SchedulersProvider {
    internal var ui: ImmediateSchedulerType = MainScheduler.instance
    internal var background: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)

    internal init() {}

    func backgroundWithQueue(_ dispatchQueue: DispatchQueue) -> ImmediateSchedulerType {
        return ConcurrentDispatchQueueScheduler(queue: dispatchQueue)
    }
}
