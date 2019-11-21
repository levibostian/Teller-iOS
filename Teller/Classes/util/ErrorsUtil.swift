import Foundation

public class ErrorsUtil {
    class func areErrorsEqual(lhs: Error?, rhs: Error?) -> Bool {
        return (lhs != nil && rhs != nil && type(of: lhs!) == type(of: rhs!) && lhs!.localizedDescription == rhs!.localizedDescription) ||
            (lhs == nil && rhs == nil)
    }
}
