import Foundation
import RxSwift

/**
 Serves as the adapter between the Repository and RepositoryDataSource. Since Teller can have different Repositories and RepositoryDataSource subclasses, having an adapter makes it much easier to interact between the two to provide the data the core Repository requires to provide the base functionality of Teller.
 */
internal protocol RepositoryDataSourceAdapter {
    associatedtype DataSource: RepositoryDataSource

    func saveCache(newCache: DataSource.FetchResult, requirements: DataSource.Requirements) throws
    func isCacheEmpty(cache: DataSource.Cache, requirements: DataSource.Requirements) -> Bool
    func observeCache(requirements: DataSource.Requirements) -> Observable<DataSource.Cache>
    func fetchFreshCache(requirements: DataSource.Requirements) -> Single<FetchResponse<DataSource.FetchResult, DataSource.FetchError>>
}

/**
 Type erasure for Repositories to use.
 */
private class _AnyRepositoryDataSourceAdapterBase<DataSource: RepositoryDataSource>: RepositoryDataSourceAdapter {
    init() {
        guard type(of: self) != _AnyRepositoryDataSourceAdapterBase.self else {
            fatalError("_AnyRepositoryDataSourceAdapterBase<AdapterType> instances can not be created; create a subclass instance instead")
        }
    }

    func saveCache(newCache: DataSource.FetchResult, requirements: DataSource.Requirements) throws {
        fatalError("Must override")
    }

    func isCacheEmpty(cache: DataSource.Cache, requirements: DataSource.Requirements) -> Bool {
        fatalError("Must override")
    }

    func observeCache(requirements: DataSource.Requirements) -> Observable<DataSource.Cache> {
        fatalError("Must override")
    }

    func fetchFreshCache(requirements: DataSource.Requirements) -> Single<FetchResponse<DataSource.FetchResult, DataSource.FetchError>> {
        fatalError("Must override")
    }
}

private final class _AnyRepositoryDataSourceAdapterBox<Concrete: RepositoryDataSourceAdapter>: _AnyRepositoryDataSourceAdapterBase<Concrete.DataSource> {
    var concrete: Concrete
    typealias DataSource = Concrete.DataSource

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override func saveCache(newCache: DataSource.FetchResult, requirements: DataSource.Requirements) throws {
        try concrete.saveCache(newCache: newCache, requirements: requirements)
    }

    override func isCacheEmpty(cache: DataSource.Cache, requirements: DataSource.Requirements) -> Bool {
        return concrete.isCacheEmpty(cache: cache, requirements: requirements)
    }

    override func observeCache(requirements: DataSource.Requirements) -> Observable<DataSource.Cache> {
        return concrete.observeCache(requirements: requirements)
    }

    override func fetchFreshCache(requirements: DataSource.Requirements) -> Single<FetchResponse<DataSource.FetchResult, DataSource.FetchError>> {
        return concrete.fetchFreshCache(requirements: requirements)
    }
}

final class AnyRepositoryDataSourceAdapter<DataSource: RepositoryDataSource>: RepositoryDataSourceAdapter {
    private let box: _AnyRepositoryDataSourceAdapterBase<DataSource>

    init<Concrete: RepositoryDataSourceAdapter>(_ concrete: Concrete) where Concrete.DataSource == DataSource {
        self.box = _AnyRepositoryDataSourceAdapterBox(concrete)
    }

    func saveCache(newCache: DataSource.FetchResult, requirements: DataSource.Requirements) throws {
        try box.saveCache(newCache: newCache, requirements: requirements)
    }

    func isCacheEmpty(cache: DataSource.Cache, requirements: DataSource.Requirements) -> Bool {
        return box.isCacheEmpty(cache: cache, requirements: requirements)
    }

    func observeCache(requirements: DataSource.Requirements) -> Observable<DataSource.Cache> {
        return box.observeCache(requirements: requirements)
    }

    func fetchFreshCache(requirements: DataSource.Requirements) -> Single<FetchResponse<DataSource.FetchResult, DataSource.FetchError>> {
        return box.fetchFreshCache(requirements: requirements)
    }
}
