//
//  IAPActions.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import StoreKit
import Foundation

enum IAPAction: ReduxAction {
    case set([SKProduct])
    case async(Async)
    enum Async {
        case fetch
        case buy(User, SKProduct)
        case restore(User)
        case validateReceipt(showLoading: Bool, User)
    }
    
}

