//
//  AppState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/09.
//

import Foundation

enum Route {
    case splash
    case onboarding
    case home 
}

struct AppState: ReduxState {
    var route: Route = .splash
    var authState: AuthState = AuthState()
    var iapState: IAPState = IAPState()
    var weightState: WeightState = WeightState()
    var reminderState: ReminderState = ReminderState()
    var reminderMessageState: ReminderMessageState = ReminderMessageState()
    var messageState: MesssageState = MesssageState()
    var healthkitState: HealthkitState = HealthkitState()
}
