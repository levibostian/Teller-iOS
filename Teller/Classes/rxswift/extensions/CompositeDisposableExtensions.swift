//
//  CompositeDisposableExtensions.swift
//  Teller
//
//  Created by Levi Bostian on 9/17/18.
//

import Foundation
import RxSwift

internal extension CompositeDisposable {
    
    static func += (left: inout CompositeDisposable, right: Disposable) {
        _ = left.insert(right)
    }
    
}
