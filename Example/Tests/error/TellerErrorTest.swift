import Foundation
@testable import Teller
import XCTest

class TellerErrorTest: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testObjectPropertiesNotSet_descriptionPopulated() {
        let propertyNotSet = "first_property"
        let property2NotSet = "second_property"
        let error = TellerError.objectPropertiesNotSet([propertyNotSet, property2NotSet])

        XCTAssertEqual(error.localizedDescription, "You forgot to set some properties in your object: \(propertyNotSet), \(property2NotSet)")
    }
}
