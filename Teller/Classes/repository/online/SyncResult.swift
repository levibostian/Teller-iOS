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
public struct SyncResult {
    let successful: Bool
    let failedError: Error?
    let skipped: SkippedReason?
    
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
    
    struct FetchFailure: Error {
        let message: String
    }
    
    public enum SkippedReason {
        /**
         * Cached cacheData already exists for the cacheData type, it's not too old yet, and force sync was not true to force sync to run.
         */
        case dataNotTooOld
    }
}
