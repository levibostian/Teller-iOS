//
//  ErrorsUtil.swift
//  Teller
//
//  Created by Levi Bostian on 9/18/18.
//

import Foundation

public class ErrorsUtil {
    
    class func areErrorsEqual(lhs: Error?, rhs: Error?) -> Bool {
        return (lhs != nil && rhs != nil && type(of: lhs!) == type(of: rhs!) && lhs!.localizedDescription == rhs!.localizedDescription) ||
            (lhs == nil && rhs == nil)
    }
    
}
