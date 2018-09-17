//
//  LocalDataStateListener.swift
//  Teller
//
//  Created by Levi Bostian on 9/14/18.
//

import Foundation

public protocol LocalDataStateListener {    
    func isEmpty()
    func data<DataType: Any>(data: DataType)
}
