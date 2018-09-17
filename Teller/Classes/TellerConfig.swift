//
//  TellerConfig.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

public class TellerConfig {
    
    public static var shared: TellerConfig = TellerConfig()
    
    private init() {
    }
    
    var appIdentifier: String = Bundle.main.bundleIdentifier!
    
}
