import Foundation

public extension DataState {
    static var testing: Testing<DataType> {
        return Testing()
    }

    class Testing<DataType: Any> {
        public func none() -> DataState<DataType> {
            return DataStateTesting.none()
        }

        public func noCache(requirements: RepositoryRequirements, more: ((inout NoCacheExistsDsl) -> Void)? = nil) -> DataState<DataType> {
            return DataStateTesting.noCache(requirements: requirements, more: more)
        }

        public func cache(requirements: RepositoryRequirements, lastTimeFetched: Date, more: ((inout CacheExistsDsl<DataType>) -> Void)? = nil) -> DataState<DataType> {
            return DataStateTesting.cache(requirements: requirements, lastTimeFetched: lastTimeFetched, more: more)
        }
    }
}
