import Foundation

public extension TellerRepository {
    static var testing: Testing {
        return Testing()
    }

    class Testing {
        public func initState(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) -> RepositoryTesting.SetValues {
            return RepositoryTesting.initState(repository: repository, requirements: requirements, more: more)
        }

        public func initStateAsync(repository: TellerRepository<DataSource>, requirements: DataSource.Requirements, onComplete: @escaping (RepositoryTesting.SetValues) -> Void, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) {
            RepositoryTesting.initStateAsync(repository: repository, requirements: requirements, onComplete: onComplete, more: more)
        }
    }
}
