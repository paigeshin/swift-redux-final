//
//  IAPState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation
import StoreKit
import Combine

enum IAPEvent: Equatable {
    case loading
    case fetch(Result<Void, GenericError>)
    case buy(Result<Void, GenericError>)
    case restore(Result<Void, GenericError>)
    case validateReceipt(Result<Void, GenericError>)
    static func == (lhs: IAPEvent, rhs: IAPEvent) -> Bool {
        switch(lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.fetch, .fetch):
            return true
        case (.buy, .buy):
            return true
        case (.validateReceipt, .validateReceipt):
            return true
        case (.restore, .restore):
            return true 
        default:
            return false
        }
    }
}

struct IAPState: ReduxState {
    var products: [SKProduct] = []
    var callback: PassthroughSubject<IAPEvent, Never> = PassthroughSubject()
    static func == (lhs: IAPState, rhs: IAPState) -> Bool {
        return lhs.products == rhs.products
    }
}
