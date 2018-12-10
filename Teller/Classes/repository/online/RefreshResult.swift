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
public struct RefreshResult: Equatable {
    
    public let successful: Bool
    public let failedError: Error?
    public let skipped: SkippedReason?
    
    private init(successful: Bool, failedError: Error?, skipped: SkippedReason?) {
        self.successful = successful
        self.failedError = failedError
        self.skipped = skipped
    }
    
    public static func success() -> RefreshResult {
        return RefreshResult(successful: true, failedError: nil, skipped: nil)
    }
    
    public static func fail(_ error: Error) -> RefreshResult {
        return RefreshResult(successful: false, failedError: error, skipped: nil)
    }
    
    public static func skipped(_ reason: SkippedReason) -> RefreshResult {
        return RefreshResult(successful: false, failedError: nil, skipped: reason)
    }
    
    public func didSkip() -> Bool {
        return skipped != nil
    }
    
    public func didFail() -> Bool {
        return failedError != nil
    }
    
    public func didSucceed() -> Bool {
        return successful
    }
    
    public static func == (lhs: RefreshResult, rhs: RefreshResult) -> Bool {
        return lhs.successful == rhs.successful &&
            lhs.skipped == rhs.skipped &&
            ErrorsUtil.areErrorsEqual(lhs: lhs.failedError, rhs: rhs.failedError)
    }
    
    public struct FetchFailure: Error {
        public let message: String
    }
    
    public enum SkippedReason {
        /**
         * Cached cacheData already exists for the cacheData type, it's not too old yet, and force sync was not true to force sync to run.
         */
        case dataNotTooOld

        /**
         The fetch call got cancelled. 
        */
        case cancelled
    }
}
