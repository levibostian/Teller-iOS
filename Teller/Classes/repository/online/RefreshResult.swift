//
//  RefreshResult.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

/**
 Result of a OnlineRepository.refresh() call.
 */
public enum RefreshResult: Equatable, CustomStringConvertible {
    
    case successful
    case failedError(error: Error)
    case skipped(reason: SkippedReason)
    
    public static func == (lhs: RefreshResult, rhs: RefreshResult) -> Bool {
        switch (lhs, rhs) {
        case (.successful, .successful):
            return true
        case (.failedError(let lhs), .failedError(let rhs)):
            return ErrorsUtil.areErrorsEqual(lhs: lhs, rhs: rhs)
        case (.skipped(let lhs), .skipped(let rhs)):
            return lhs == rhs
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case .successful: return "successful"
        case .failedError(let error): return "failed. Description: \(error.localizedDescription)"
        case .skipped(let reason): return "skipped. Reason: \(reason.description)"
        }
    }
    
    public struct FetchFailure: Error {
        public let message: String
    }
    
    public enum SkippedReason: CustomStringConvertible {
        /**
         * Cached cacheData already exists for the cacheData type, it's not too old yet, and force sync was not true to force sync to run.
         */
        case dataNotTooOld

        /**
         The fetch call got cancelled. 
        */
        case cancelled
        
        public var description: String {
            switch self {
            case .dataNotTooOld: return "data not too old"
            case .cancelled: return "cancelled"
            }
        }
    }
}
