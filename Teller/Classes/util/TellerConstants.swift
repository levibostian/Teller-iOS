//
//  TellerConstants.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

internal class TellerConstants {
    
    internal static let userDefaultsPrefix = "TELLER_"
    // Avoid using the UserDefaults.shared to prevent using the same one as the app and cause confusion/collision. 
    internal static let userDefaults: UserDefaults = UserDefaults.init(suiteName: "\(TellerConfig.shared.appIdentifier)_Teller")!
    
}
