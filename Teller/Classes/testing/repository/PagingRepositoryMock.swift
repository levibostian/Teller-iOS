import Foundation
import RxSwift

/**
 Mock Teller's `PagingRepository`. Meant to be used with unit tests where you use `PagingRepository`.

 Note: Unit tests will not fully test your implementation of Teller in your app. Create a mix of unit and integration tests in order to get good test coverage.
 */
public class TellerPagingRepositoryMock<DataSource: PagingRepositoryDataSource>: TellerPagingRepository<DataSource> {
    public var pagingRequirementsCallsCount = 0
    public var pagingRequirementsCalled: Bool {
        return pagingRequirementsCallsCount > 0
    }

    public var pagingRequirementsInvocations: [DataSource.PagingRequirements] = []

    override public var pagingRequirements: DataSource.PagingRequirements {
        didSet {
            mockCalled = true
            pagingRequirementsCallsCount += 1
            pagingRequirementsInvocations.append(pagingRequirements)
        }
    }

    /**
     Below is a direct copy/paste from Repository mock.
     */

    public var mockCalled: Bool = false // if *any* interactions done on mock. Sets/gets or methods called.

    public var requirementsCallsCount = 0
    public var requirementsCalled: Bool {
        return requirementsCallsCount > 0
    }

    public var requirementsInvocations: [DataSource.Requirements?] = []

    override public var requirements: DataSource.Requirements? {
        didSet {
            mockCalled = true
            requirementsCallsCount += 1
            requirementsInvocations.append(requirements)
        }
    }

    override public func newRequirementsSet(_ requirements: DataSource.Requirements?) {
        // don't do anything. This is simply to prevent super being called.
    }

    public var refreshCallsCount = 0
    public var refreshCalled: Bool {
        return refreshCallsCount > 0
    }

    public var refreshInvocations: [Bool] = []
    public var refreshClosure: ((Bool) -> Single<RefreshResult>)?

    override public func refresh(force: Bool) throws -> Single<RefreshResult> {
        _ = try refreshAssert()

        mockCalled = true
        refreshCallsCount += 1
        refreshInvocations.append(force)
        return refreshClosure!(force)
    }

    public var refreshIfNoCacheCallsCount = 0
    public var refreshIfNoCacheCalled: Bool {
        return refreshIfNoCacheCallsCount > 0
    }

    public var refreshIfNoCacheClosure: (() -> Single<RefreshResult>)?

    override public func refreshIfNoCache() throws -> Single<RefreshResult> {
        _ = try refreshAssert()

        mockCalled = true
        refreshIfNoCacheCallsCount += 1
        return refreshIfNoCacheClosure!()
    }

    public var observeCallsCount = 0
    public var observeCalled: Bool {
        return observeCallsCount > 0
    }

    public var observeClosure: (() -> Observable<CacheState<DataSource.Cache>>)?

    override public func observe() -> Observable<CacheState<DataSource.Cache>> {
        mockCalled = true
        observeCallsCount += 1
        return observeClosure!()
    }
}
