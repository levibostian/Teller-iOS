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
public typealias FetchResponse<DataType: Any> = Result<DataType, Swift.Error>
