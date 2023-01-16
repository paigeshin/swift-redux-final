//
//  HealthKitAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/24.
//

import Foundation

enum HealthkitAction: ReduxAction {
    case async(Async)
    enum Async {
        case create(Weight)
        case request
        case delete(Weight)
    }
}
