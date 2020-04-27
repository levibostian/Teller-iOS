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

    func get<T: Any>(_ getValue: (DataType) -> T) -> T {
        return queue.sync {
            getValue(value)
        }
    }

    func set(_ newValue: DataType) {
        queue.sync {
            value = newValue
        }
    }

    func set(handler: (DataType) -> DataType) -> DataType {
        return queue.sync {
            let currentValue = value
            let newValue = handler(currentValue)

            value = newValue

            return newValue
        }
    }

    func setMap<Return: Any>(handler: (DataType) -> (newValue: DataType, return: Return)) -> Return {
        return queue.sync {
            let currentValue = value
            let newValue = handler(currentValue)

            value = newValue.newValue

            return newValue.return
        }
    }
}
