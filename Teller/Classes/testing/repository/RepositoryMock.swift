import Foundation
import RxSwift

/**
 Mock Teller's `Repository`. Meant to be used with unit tests where you use `Repository`.

 Note: Unit tests will not fully test your implementation of Teller in your app. Create a mix of unit and integration tests in order to get good test coverage.
 */
public class RepositoryMock<DataSource: RepositoryDataSource>: Repository<DataSource> {
    public var mockCalled: Bool = false // if *any* interactions done on mock. Sets/gets or methods called.

    public var requirementsCallsCount = 0
    public var requirementsCalled: Bool {
        return requirementsCallsCount > 0
    }

    public var requirementsInvocations: [DataSource.Requirements?] = []

    public override var requirements: DataSource.Requirements? {
        didSet {
            mockCalled = true
            requirementsCallsCount += 1
            requirementsInvocations.append(requirements)
        }
    }

    public override func newRequirementsSet(_ requirements: DataSource.Requirements?) {
        // don't do anything. This is simply to prevent super being called.
    }

    public var refreshCallsCount = 0
    public var refreshCalled: Bool {
        return refreshCallsCount > 0
    }

    public var refreshInvocations: [Bool] = []
    public var refreshClosure: ((Bool) -> Single<RefreshResult>)?

    public override func refresh(force: Bool) throws -> Single<RefreshResult> {
        mockCalled = true
        refreshCallsCount += 1
        refreshInvocations.append(force)
        return refreshClosure!(force)
    }

    public var observeCallsCount = 0
    public var observeCalled: Bool {
        return observeCallsCount > 0
    }

    public var observeClosure: (() -> Observable<DataState<DataSource.Cache>>)?

    public override func observe() -> Observable<DataState<DataSource.Cache>> {
        mockCalled = true
        observeCallsCount += 1
        return observeClosure!()
    }
}
