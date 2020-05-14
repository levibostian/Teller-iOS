import Foundation

extension Data {
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}
