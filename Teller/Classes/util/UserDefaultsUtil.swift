//
//  UserDefaultsUtil.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

internal protocol UserDefaultsUtil {
    func clear()
}

internal class TellerUserDefaultsUtil: UserDefaultsUtil {

    public static var shared: TellerUserDefaultsUtil = TellerUserDefaultsUtil()

    private init() {
    }
    
    internal func clear() {
        let userDefaults = TellerConstants.userDefaults
        
        userDefaults.dictionaryRepresentation().forEach { (key, value) in
            if (key.starts(with: TellerConstants.userDefaultsPrefix)) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
}
