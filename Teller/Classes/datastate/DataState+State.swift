import Foundation

extension CacheState {
    /**
     Parse the `DataState` for you to more easily display the state of the cache in your UI.

     The enum cases have very little parameters in them. In the past, Teller had a long list of 4-8 parameters. This made the code not as maintainable and hard to use when using in an app because you may have 75% of those params not being used. We go with the design now that you can access the public properties of `CacheState` if you want them and we provide only the most relevant parameters to you. For example: it is not very helpful to include the state of refreshing in each of the cases because in the UI of your app you are more then likely handling the refreshing not in the enum cases but outside of that in 1 place. Why provide parameters that are not relevant to that block of code?
     */
    public enum State {
        /**
         A cache has not been successfully fetched before.

         fetching - is a cache being fetched right now
         errorDuringFetch - a fetch just finished but there was an error.
         */
        case noCache
        /**
         A cache has been successfully fetched before. The cache might be empty, though!

         We have decided to combine the "cache empty, but exists" and the "cache exists and is not empty" states into 1 enum case here. That's because in the UI of your app you may share some of the same code for both of these choices. Therefore, it's best to combine the two to prevent lots of duplicate code for your app.
         */
        case cache(cache: CacheType?, cacheAge: Date)
    }

    public var state: State {
        if isNone {
            fatalError("Should not happen. Observing of a cache state should ignore none states")
        }

        if !cacheExists {
            return State.noCache
        } else {
            return State.cache(cache: cache, cacheAge: cacheAge!)
        }
    }
}
