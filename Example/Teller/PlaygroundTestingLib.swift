//
//  PlaygroundTestingLib.swift
//  Teller_Example
//
//  Created by Levi Bostian on 9/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Teller

// This file only exists temporarily. It exists to make sure that the Teller Testing portion of the library is accessible to the public.
// This file will be replaced by example unit tests against the example app using the example app's code base which will give an example to users of the library how to write unit tests against their own code base for Teller.
class PlaygroundTestingLib {

    func test_OnlineDataStateTesting_none() {
        let _: OnlineDataState<String> = OnlineDataStateTesting.none()

        let _: OnlineDataState<String> = OnlineDataState.testing.none()
    }

    func test_OnlineDataStateTesting_noCache() {
        let requirements = ReposRepositoryGetDataRequirements(username: "")

        let _: OnlineDataState<String> = OnlineDataStateTesting.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }

        let _: OnlineDataState<String> = OnlineDataState.testing.noCache(requirements: requirements) {
            $0.fetchingFirstTime()
        }
    }

    func test_OnlineDataStateTesting_cache() {
        let requirements = ReposRepositoryGetDataRequirements(username: "")

        let _: OnlineDataState<String> = OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: Date()) {
            $0.successfulFetch(timeFetched: Date())
        }

        let _: OnlineDataState<String> = OnlineDataState.testing.cache(requirements: requirements, lastTimeFetched: Date()) {
            $0.successfulFetch(timeFetched: Date())
        }
    }
}
