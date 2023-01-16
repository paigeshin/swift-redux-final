//
//  reminderMessageReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/18.
//

import Foundation

func reminderMessageReducer(_ state: ReminderMessageState, _ action: ReminderMessageAction) -> ReminderMessageState {
    var state: ReminderMessageState = state
    switch action {
    case .set(let messages):
        state.reminderMessages = messages
    case .clear:
        state.reminderMessages = []
    default: break
    }
    return state
}
