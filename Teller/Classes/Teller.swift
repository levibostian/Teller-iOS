import Foundation

/**
 Misc tasks for Teller.
 */
public class Teller {
    /**
     Sigleton instance of Teller.
     */
    public static var shared: Teller = Teller()

    private let userDefaultsUtil: UserDefaultsUtil

    internal init(userDefaultsUtil: UserDefaultsUtil) {
        self.userDefaultsUtil = userDefaultsUtil
    }

    private convenience init() {
        self.init(userDefaultsUtil: TellerUserDefaultsUtil.shared)
    }

    /**
     Deletes all Teller data.
     */
    public func clear() {
        deleteAllData()
    }

    private func deleteAllData() {
        userDefaultsUtil.clear()
    }
}
