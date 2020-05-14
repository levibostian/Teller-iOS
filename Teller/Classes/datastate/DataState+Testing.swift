import Foundation

public extension CacheState {
    static var testing: Testing<CacheType> {
        return Testing()
    }

    class Testing<DataType: Any> {
        public func none() -> CacheState<DataType> {
            return CacheStateTesting.none()
        }

        public func noCache(requirements: RepositoryRequirements, more: ((inout NoCacheExistsDsl) -> Void)? = nil) -> CacheState<DataType> {
            return CacheStateTesting.noCache(requirements: requirements, more: more)
        }

        public func cache(requirements: RepositoryRequirements, lastTimeFetched: Date, more: ((inout CacheExistsDsl<DataType>) -> Void)? = nil) -> CacheState<DataType> {
            return CacheStateTesting.cache(requirements: requirements, lastTimeFetched: lastTimeFetched, more: more)
        }
    }
}
