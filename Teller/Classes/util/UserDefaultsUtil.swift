import Foundation

internal protocol UserDefaultsUtil {
    func clear()
}

internal class TellerUserDefaultsUtil: UserDefaultsUtil {
    public static var shared: TellerUserDefaultsUtil = TellerUserDefaultsUtil()

    private init() {}

    internal func clear() {
        let userDefaults = TellerConstants.userDefaults

        userDefaults.dictionaryRepresentation().forEach { key, _ in
            if key.starts(with: TellerConstants.userDefaultsPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
