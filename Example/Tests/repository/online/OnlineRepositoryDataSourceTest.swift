import RxSwift
@testable import Teller
import XCTest

class OnlineRepositoryDataSourceTest: XCTestCase {
    private var dataSource: MockOnlineRepositoryDataSource!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        TellerUserDefaultsUtil.shared.clear()
        userDefaults = TellerConstants.userDefaults
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func initDataSource(fakeData: MockOnlineRepositoryDataSource.FakeData = MockOnlineRepositoryDataSource.FakeData(isDataEmpty: false, observeCachedData: Observable.empty(), fetchFreshData: Single.never()), maxAgeOfData: Period = Period(unit: 1, component: Calendar.Component.second)) {
        dataSource = MockOnlineRepositoryDataSource(fakeData: fakeData, maxAgeOfData: maxAgeOfData)
    }
}
