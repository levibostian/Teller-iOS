//
//  Teller.swift
//  Pods-Teller_Example
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

public class Teller {
    
    public static var shared: Teller = Teller()
    
    private init() {
    }
    
    /**
     Delete all data for Teller.
     */
    public func clear() {
        UserDefaultsUtil.clear()
    }
    
}
