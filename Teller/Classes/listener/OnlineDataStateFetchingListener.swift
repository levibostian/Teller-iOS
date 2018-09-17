//
//  OnlineDataStateFetchingListener.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

public protocol OnlineDataStateFetchingListener {
    
    func fetchingFreshCacheData()
    /**
     * Fetching of fresh data to put into the cache has been completed successfully or not. If [errorDuringFetch] is not null, then it was a fail if it is null it was successful.
     *
     * It's a best practice to show a UI to the user when data is done being fetched. Here is a tip for you: Sometimes in your app, a fetch can be very fast. It's not a good idea to show a UI to your user during fetching (when [fetchingFreshCacheData] was called) that says something like "Syncing your profile..." and then when [finishedFetchingFreshCacheData] gets called you change the UI to "Done!". What if that network call to fetch fresh data took 0.5 seconds? The user will see a message "Done!" and wonder, "What is done?!" It's recommended to use more descriptive messages such as "Your profile is up-to-date" or have a progress dialog that fades away to indicate the sync is complete and use the [cacheData] `fetched` parameter to show the user that data is only seconds old and has been fetched successfully. This may sounds complex but think of this while developing: If my user does not see the UI I show them when [fetchingFreshCacheData] is called but they see the UI when [finishedFetchingFreshCacheData] is called, will they be confused?
     *
     * @param errorDuringFetch Error that occurred during the fetch of getting first set of cacheData. It is up to you to capture this error and determine how to show it to the user. Since it is during the fetch only, it's best practice here to show this error to the user, but in a UI independent from showing the empty or cached data UI since [cacheEmpty] or [cacheData] will have been called as well in the listener. If you have a situation where an error occur during fetching fresh data but it's not super important to show to the user, it's something you only want to show for a few seconds and then dismiss, or you need to show the user in a UI that forces them to acknowledge it, it's best practice for you to create a [Throwable] subclass and return that in [OnlineRepository.FetchResponse.fail] which will then show up here. You can then parse the [Throwable] subclass in your listener to determine what to do with the error. It's also best practice to create custom views/custom dialog fragments to handle errors so you only need to write code once to handle specific errors across your app.
     */
    func finishedFetchingFreshCacheData(errorDuringFetch: Error?)
}
