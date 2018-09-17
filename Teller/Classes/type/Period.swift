//
//  AgeOfData.swift
//  Teller
//
//  Created by Levi Bostian on 9/16/18.
//

import Foundation

public struct Period {
    let unit: Int
    let component: NSCalendar.Unit
}

public extension Period {
    
    func toDate() -> Date {
        return NSCalendar(identifier: NSCalendar.Identifier.gregorian)!.date(byAdding: self.component, value: -self.unit, to: Date(), options: NSCalendar.Options())!
    }
    
}
