import Foundation
import RxSwift

open class LocalRepository<DataSource: LocalRepositoryDataSource> {
    public let dataSource: DataSource
    internal let schedulersProvider: SchedulersProvider

    internal var observeCacheDisposable: Disposable?
    internal var currentStateOfData: LocalDataStateCompoundBehaviorSubject<DataSource.Cache> = LocalDataStateCompoundBehaviorSubject()

    public var requirements: DataSource.GetDataRequirements? {
        didSet {
            currentStateOfData.resetStateToNone()

            if let requirements = requirements {
                beginObservingCachedData(requirements: requirements)
            }
        }
    }

    public init(dataSource: DataSource) {
        self.dataSource = dataSource
        self.schedulersProvider = AppSchedulersProvider()
    }

    internal init(dataSource: DataSource, schedulersProvider: SchedulersProvider) {
        self.dataSource = dataSource
        self.schedulersProvider = schedulersProvider
    }

    deinit {
        currentStateOfData.subject.on(.completed)
        currentStateOfData.subject.dispose()

        observeCacheDisposable?.dispose()
    }

    public final func newCache(_ cache: DataSource.Cache) {
        do {
            try dataSource.saveData(data: cache)
        } catch {
            currentStateOfData.onNextError(error)
        }
    }

    fileprivate func beginObservingCachedData(requirements: DataSource.GetDataRequirements) {
        observeCacheDisposable?.dispose()

        observeCacheDisposable = dataSource.observeCachedData()
            .subscribeOn(schedulersProvider.ui)
            .subscribe(onNext: { [weak self] cachedData in
                guard let self = self else { return }

                if self.dataSource.isDataEmpty(data: cachedData) {
                    self.currentStateOfData.onNextEmpty()
                } else {
                    self.currentStateOfData.onNextData(data: cachedData)
                }
            })
    }

    /**
     * Get an observable that gets the current state of data and all future states.
     */
    public final func observe() -> Observable<LocalDataState<DataSource.Cache>> {
        return currentStateOfData.subject
    }
}
