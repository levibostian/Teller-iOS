import Foundation

extension String {
    var data: Data? {
        return data(using: .utf8)
    }
}
