//
//  TellerError.swift
//  Teller
//
//  Created by Levi Bostian on 10/19/18.
//

import Foundation

/// A type representing possible errors Teller can throw.
public enum TellerError: Swift.Error {
    
    /// You forgot to set some properties in an Object. Your request cannot be satisfied until that is done.
    case objectPropertiesNotSet([String])
    
}

extension TellerError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .objectPropertiesNotSet(let properties):
            return "You forgot to set some properties in your object: \(properties.joined(separator: ", "))"
        }
    }
    
}
