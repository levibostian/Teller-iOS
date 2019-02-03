//
//  TestsSchedulersProvider.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 10/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
@testable import Teller

/**
 This exists specifically for tests. It means to run the code on the same thread you are currently on. This allows Rx code to perform more like synchronous code.

 You may want sync code for *some* tests when you are asserting that an action is being performed. If you have a test that is saying, "If I set this variable, a refresh should be triggered and new cache data is available". If you were having Rx run on separate threads, this test would be very difficult to assert because you would need to wait X cycles for data to get back. These tests are only testing that actions are performed, not the result. Those are separate tests and can use separate schedulers for the real test.
 */
internal class TestsSchedulersProvider: SchedulersProvider {

    var ui: ImmediateSchedulerType = CurrentThreadScheduler.instance
    var background: ImmediateSchedulerType = CurrentThreadScheduler.instance

    func backgroundWithQueue(_ dispatchQueue: DispatchQueue) -> ImmediateSchedulerType {
        return background
    }
    
}
