import Foundation
import RxCocoa
import RxSwift

enum KeyValueStorageKey: String, Codable {
    case repos
}

protocol KeyValueStorage {
    func integer(forKey key: KeyValueStorageKey) -> Int?
    func setInt(_ value: Int?, forKey key: KeyValueStorageKey)
    func double(forKey key: KeyValueStorageKey) -> Double?
    func setDouble(_ value: Double?, forKey key: KeyValueStorageKey)
    func string(forKey key: KeyValueStorageKey) -> String?
    func setString(_ value: String?, forKey key: KeyValueStorageKey)
    func date(forKey key: KeyValueStorageKey) -> Date?
    func setDate(_ value: Date?, forKey key: KeyValueStorageKey)
    // Does not emit when value is nil
    func observeString(forKey key: KeyValueStorageKey) -> Observable<String>
    func delete(key: KeyValueStorageKey)
    func deleteAll()
}

// sourcery: InjectRegister = "KeyValueStorage"
class UserDefaultsKeyValueStorage: KeyValueStorage {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func integer(forKey key: KeyValueStorageKey) -> Int? {
        let value = userDefaults.integer(forKey: key.rawValue)
        return value == 0 ? nil : value
    }

    func setInt(_ value: Int?, forKey key: KeyValueStorageKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func double(forKey key: KeyValueStorageKey) -> Double? {
        let value = userDefaults.double(forKey: key.rawValue)
        return value == 0 ? nil : value
    }

    func setDouble(_ value: Double?, forKey key: KeyValueStorageKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func string(forKey key: KeyValueStorageKey) -> String? {
        return userDefaults.string(forKey: key.rawValue)
    }

    func setString(_ value: String?, forKey key: KeyValueStorageKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func date(forKey key: KeyValueStorageKey) -> Date? {
        let millis = userDefaults.double(forKey: key.rawValue)
        guard millis > 0 else {
            return nil
        }

        return Date(timeIntervalSince1970: millis)
    }

    func setDate(_ value: Date?, forKey key: KeyValueStorageKey) {
        userDefaults.set(value?.timeIntervalSince1970, forKey: key.rawValue)
    }

    func observeString(forKey key: KeyValueStorageKey) -> Observable<String> {
        return userDefaults.rx.observe(String.self, key.rawValue)
            .filter { (value) -> Bool in
                value != nil
            }.map { (value) -> String in
                value!
            }
    }

    func delete(key: KeyValueStorageKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }

    func deleteAll() {
        userDefaults.dictionaryRepresentation().keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}
