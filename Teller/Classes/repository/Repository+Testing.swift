import Foundation

public extension Repository {
    static var testing: Testing {
        return Testing()
    }

    class Testing {
        public func initState(repository: Repository<DataSource>, requirements: DataSource.Requirements, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) -> RepositoryTesting.SetValues {
            return RepositoryTesting.initState(repository: repository, requirements: requirements, more: more)
        }

        public func initStateAsync(repository: Repository<DataSource>, requirements: DataSource.Requirements, onComplete: @escaping (RepositoryTesting.SetValues) -> Void, more: ((inout StateOfOnlineRepositoryDsl<DataSource.FetchResult>) -> Void)? = nil) {
            RepositoryTesting.initStateAsync(repository: repository, requirements: requirements, onComplete: onComplete, more: more)
        }
    }
}
