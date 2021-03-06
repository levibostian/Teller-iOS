import Foundation
import RxBlocking
import RxSwift
import Teller

// This file only exists temporarily. It exists to make sure that the Teller Testing portion of the library is accessible to the public.
// This file will be replaced by example unit tests against the example app using the example app's code base which will give an example to users of the library how to write unit tests against their own code base for Teller.
class PlaygroundTestingLib {
    func test_DataStateTesting_noCache() {
        let requirements = ReposRepositoryRequirements(username: "")

        let _: CacheState<String> = CacheStateTesting.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }

        let _: CacheState<String> = CacheState.testing.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }
    }

    func test_DataStateTesting_cache() {
        let requirements = ReposRepositoryRequirements(username: "")

        let _: CacheState<String> = CacheStateTesting.cache(requirements: requirements, lastTimeFetched: Date()) {
            $0.successfulFetch(timeFetched: Date())
        }

        let _: CacheState<String> = CacheState.testing.cache(requirements: requirements, lastTimeFetched: Date()) {
            $0.successfulFetch(timeFetched: Date())
        }
    }
}
