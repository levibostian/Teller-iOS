//
//  OnlineDataStateFirstFetchListener.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

public protocol OnlineDataStateFirstFetchListener {
    func firstFetchOfData()
    /**
     * @param errorDuringFetch Error that occurred during the fetch of getting first set of cacheData. It is up to you to capture this error and determine how to show it to the user. It's best practice that when there is an error here, you will dismiss a loading UI if you are showing one since [firstFetchOfData] was called before.
     */
    func finishedFirstFetchOfData(errorDuringFetch: Error?)
}
