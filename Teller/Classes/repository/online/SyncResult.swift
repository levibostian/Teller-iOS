//
//  SyncResult.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

/**
 Result of a OnlineRepository.sync() call.
 */
public struct SyncResult: Equatable {
    
    public let successful: Bool
    public let failedError: Error?
    public let skipped: SkippedReason?
    
    private init(successful: Bool, failedError: Error?, skipped: SkippedReason?) {
        self.successful = successful
        self.failedError = failedError
        self.skipped = skipped
    }
    
    public static func success() -> SyncResult {
        return SyncResult(successful: true, failedError: nil, skipped: nil)
    }
    
    public static func fail(_ error: Error) -> SyncResult {
        return SyncResult(successful: false, failedError: error, skipped: nil)
    }
    
    public static func skipped(_ reason: SkippedReason) -> SyncResult {
        return SyncResult(successful: false, failedError: nil, skipped: reason)
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
    
    public static func == (lhs: SyncResult, rhs: SyncResult) -> Bool {
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
    }
}
