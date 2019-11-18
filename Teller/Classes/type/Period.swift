import Foundation

public struct Period {
    public let unit: Int
    public let component: Calendar.Component

    public init(unit: Int, component: Calendar.Component) {
        self.unit = unit
        self.component = component
    }
}

public extension Period {
    func toDate() -> Date {
        return Calendar(identifier: Calendar.Identifier.gregorian).date(byAdding: component, value: -unit, to: Date())!
    }
}
