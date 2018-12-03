//
//  Teller.swift
//  Teller
//
//  Created by Levi Bostian on 12/3/18.
//

import Foundation

/**
 Misc tasks for Teller. 
 */
public class Teller {

    /**
     Sigleton instance of Teller.
     */
    public static var shared: Teller = Teller()

    fileprivate let userDefaultsUtil: UserDefaultsUtil

    internal init(userDefaultsUtil: UserDefaultsUtil) {
        self.userDefaultsUtil = userDefaultsUtil
    }

    private convenience init() {
        self.init(userDefaultsUtil: TellerUserDefaultsUtil.shared)
    }

    /**
     Deletes all Teller data.
     */
    public func clear() {
        deleteAllData()
    }

    private func deleteAllData() {
        userDefaultsUtil.clear()
    }

}
