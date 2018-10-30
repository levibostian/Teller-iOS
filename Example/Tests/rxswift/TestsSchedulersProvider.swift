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

internal class TestsSchedulersProvider: SchedulersProvider {
    
    var ui: ImmediateSchedulerType = CurrentThreadScheduler.instance
    var background: ImmediateSchedulerType = CurrentThreadScheduler.instance
    
}
