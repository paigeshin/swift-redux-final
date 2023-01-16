//
//  appReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/09.
//

import Foundation

func appReducer(_ state: AppState, _ action: AppAction) -> AppState {
    var state: AppState = state
    switch action {
    case .navigate(let route):
        state.route = route
    case .auth(let authAction):
        state.authState = authReducer(state.authState, authAction)
    case .weight(let weightAction):
        state.weightState = weightReducer(state.weightState, weightAction)
    case .iap(let iapAction):
        state.iapState = iapReducer(state.iapState, iapAction)
    case .reminder(let reminderAction):
        state.reminderState = reminderReducer(state.reminderState, reminderAction)
    case .reminderMessage(let reminderMessageAction):
        state.reminderMessageState = reminderMessageReducer(state.reminderMessageState, reminderMessageAction)
    case .message(let messageAction):
        state.messageState = messageReducer(state.messageState, messageAction)
    case .healthkit(let heatlthkitAction):
        state.healthkitState = healthkitReducer(state.healthkitState, heatlthkitAction)
    }
    return state
}
