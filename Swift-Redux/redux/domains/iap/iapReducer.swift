//
//  iapReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation

func iapReducer(_ state: IAPState, _ action: IAPAction) -> IAPState {
    var state: IAPState = state
    switch action {
    case .set(let products):
        state.products = products
    default: break 
    }
    return state
}
