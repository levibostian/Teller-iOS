import Foundation

public extension OnlineDataState {
    static var testing: Testing<DataType> {
        return Testing()
    }

    class Testing<DataType: Any> {
        public func none() -> OnlineDataState<DataType> {
            return OnlineDataStateTesting.none()
        }

        public func noCache(requirements: OnlineRepositoryGetDataRequirements, more: ((inout NoCacheExistsDsl) -> Void)? = nil) -> OnlineDataState<DataType> {
            return OnlineDataStateTesting.noCache(requirements: requirements, more: more)
        }

        public func cache(requirements: OnlineRepositoryGetDataRequirements, lastTimeFetched: Date, more: ((inout CacheExistsDsl<DataType>) -> Void)? = nil) -> OnlineDataState<DataType> {
            return OnlineDataStateTesting.cache(requirements: requirements, lastTimeFetched: lastTimeFetched, more: more)
        }
    }
}
