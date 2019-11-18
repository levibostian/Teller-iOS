import Foundation
@testable import Teller

internal class UserDefaultsUtilMock: UserDefaultsUtil {
    var invokedClear = false
    var invokedClearCount = 0
    func clear() {
        invokedClear = true
        invokedClearCount += 1
    }
}
