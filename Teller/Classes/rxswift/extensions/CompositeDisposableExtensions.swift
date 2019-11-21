import Foundation
import RxSwift

internal extension CompositeDisposable {
    static func += (left: inout CompositeDisposable, right: Disposable) {
        _ = left.insert(right)
    }
}
