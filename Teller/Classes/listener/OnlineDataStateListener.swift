//
//  OnlineDataStateListener.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

public protocol OnlineDataStateListener: OnlineDataStateFetchingListener, OnlineDataStateFirstFetchListener, OnlineDataStateCacheListener {
}
