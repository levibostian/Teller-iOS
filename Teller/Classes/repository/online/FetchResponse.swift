//
//  FetchResponse.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation

/**
 Result of a OnlineRepositoryDataSource.fetchFreshData call. It's an object that is generic enough that OnlineRepository can understand it.
 */
public struct FetchResponse<DataType: Any> {
    
    public let data: DataType?
    public let failure: Error?
    
    private init(data: DataType?, failure: Error?) {
        self.data = data
        self.failure = failure
    }
    
    public static func success(data: DataType) -> FetchResponse {
        return FetchResponse(data: data, failure: nil)
    }
    
    public static func fail(message: String) -> FetchResponse {
        return FetchResponse(data: nil, failure: FetchFailure(message: message))
    }
    
    public static func fail(error: Error) -> FetchResponse {
        return FetchResponse(data: nil, failure: error)
    }
    
    public func isSuccessful() -> Bool {
        return data != nil
    }
    
    public func isFailure() -> Bool {
        return self.failure != nil
    }
    
    public struct FetchFailure: Error {
        let message: String
    }
}
