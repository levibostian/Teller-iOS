import Foundation

internal class TellerConstants {
    internal static let namespace = "com.levibostian.teller"

    internal static let userDefaultsPrefix = "TELLER_"
    /**
     Dev note: I am using the standard app's UserDefaults here because:
     1. You are supposed to use UserDefaults.standard when you have shared prefs you want to save to the host app and the host app only. I don't see a scenario where we will be needing to share the UserDefaults with other apps or Extensions.
     2. I can simply have a prefix for all keys and remove those when I choose to to not touch others.
     */
    internal static let userDefaults: UserDefaults = UserDefaults.standard
}
