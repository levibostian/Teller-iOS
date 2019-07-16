//
//  LocalDataState+State.swift
//  Teller
//
//  Created by Levi Bostian on 9/19/18.
//

import Foundation

extension LocalDataState {
    
    public enum State {
        case isEmpty
        case data(data: DataType)
    }
    
    /**
     * This is usually used in the UI of an app to display data to a user.
     * Use a switch statement to view each of the following states.
     */
    public func state() -> State? {
        if (isEmpty) {
            return State.isEmpty
        }
        if let data = self.data {
            return State.data(data: data)
        }
        return nil
    }
    
}

extension LocalDataState.State: Equatable where DataType: Equatable {
    
    public static func == (lhs: LocalDataState<DataType>.State, rhs: LocalDataState<DataType>.State) -> Bool {
        switch (lhs, rhs) {
        case (.isEmpty, .isEmpty):
            return true
        case (let .data(data1), let .data(data2)):
            return data1 == data2
        default:
            return false
        }
    }
    
}
