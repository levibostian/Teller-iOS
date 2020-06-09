import Foundation

// `DataType` can be optional or non-optional. It's all defined by the generic you pass: `Atomic<String?>` vs `Atomic<String>`.
internal class Atomic<DataType: Any> {
    fileprivate let queue = DispatchQueue(label: "Atomic")

    fileprivate var value: DataType

    init(value: DataType) {
        self.value = value
    }

    var get: DataType {
        return queue.sync { () -> DataType in
            value
        }
    }

    func set(_ newValue: DataType) {
        queue.sync {
            value = newValue
        }
    }
}
