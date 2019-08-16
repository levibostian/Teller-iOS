//
//  LocalDataState+State.swift
//  Teller
//
//  Created by Levi Bostian on 9/19/18.
//

import Foundation

extension LocalDataState {
    
    public enum State {
        case isEmpty(error: Error?)
        case data(data: DataType, error: Error?)
    }
    
    /**
     * This is usually used in the UI of an app to display data to a user.
     * Use a switch statement to view each of the following states.
     */
    public func state() -> State? {
        if (isEmpty) {
            return State.isEmpty(error: self.error)
        }
        if let data = self.data {
            return State.data(data: data, error: self.error)
        }
        return nil
    }
}

extension LocalDataState.State: Equatable where DataType: Equatable {
    
    public static func == (lhs: LocalDataState<DataType>.State, rhs: LocalDataState<DataType>.State) -> Bool {
        switch (lhs, rhs) {
        case (let .isEmpty(error1), let .isEmpty(error2)):
            return ErrorsUtil.areErrorsEqual(lhs: error1, rhs: error2)
        case (let .data(data1, error1), let .data(data2, error2)):
            return data1 == data2 && ErrorsUtil.areErrorsEqual(lhs: error1, rhs: error2)
        default:
            return false
        }
    }
    
}
