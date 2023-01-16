//
//  HealthKitState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/24.
//

import Combine
import Foundation

enum HealthkitEvent: Equatable {
    case create(Result<Bool, GenericError>)
    case request(Result<Bool, GenericError>)
    case delete(Result<Bool, GenericError>)
    static func == (lhs: HealthkitEvent, rhs: HealthkitEvent) -> Bool {
        switch(lhs, rhs) {
        case (.request, .request):
            return true 
        case (.create, .create):
            return true
        case (.delete, .delete):
            return true
        default:
            return false
        }
    }
}

struct HealthkitState: ReduxState {
    var callback: PassthroughSubject<HealthkitEvent, Never> = PassthroughSubject()
    static func == (lhs: HealthkitState, rhs: HealthkitState) -> Bool {
        return true
    }
}
