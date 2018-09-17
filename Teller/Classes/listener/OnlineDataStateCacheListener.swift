//
//  OnlineDataStateCacheListener.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

public protocol OnlineDataStateCacheListener {
    func cacheEmpty()
    func cacheData<DataType: Any>(data: DataType, fetched: Date)
}
