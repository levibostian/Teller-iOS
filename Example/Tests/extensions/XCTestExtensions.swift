import Foundation
import XCTest

extension XCTest {
    func XCTAssertNewer(_ newer: Date, _ older: Date, file: StaticString = #file, line: UInt = #line) {
        XCTAssertGreaterThan(newer.timeIntervalSince1970, older.timeIntervalSince1970, "\(newer) is *not* newer then \(older)", file: file, line: line)
    }

    func XCTAssertOlder(_ older: Date, _ newer: Date, file: StaticString = #file, line: UInt = #line) {
        XCTAssertGreaterThan(older.timeIntervalSince1970, newer.timeIntervalSince1970, "\(older) is *not* older then \(newer)", file: file, line: line)
    }

    func XCTAssertEqualDate(_ one: Date, _ two: Date, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(one.timeIntervalSinceReferenceDate, two.timeIntervalSinceReferenceDate, accuracy: 0.001, "\(one) is *not* equal to \(two)", file: file, line: line)
    }
}
