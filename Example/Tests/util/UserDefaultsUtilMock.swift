//
//  UserDefaultsUtilMock.swift
//  Teller_Tests
//
//  Created by Levi Bostian on 12/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import Teller

internal class UserDefaultsUtilMock: UserDefaultsUtil {    
    var invokedClear = false
    var invokedClearCount = 0
    func clear() {
        invokedClear = true
        invokedClearCount += 1
    }
}
