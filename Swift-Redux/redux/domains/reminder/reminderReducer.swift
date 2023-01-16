//
//  reminderReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/15.
//

import Foundation

func reminderReducer(_ state: ReminderState, _ action: ReminderAction) -> ReminderState {
    var state: ReminderState = state
    switch action {
    case .set(let reminders):
        state.reminders = reminders
    case .clear:
        state.reminders = [] 
    default: break
    }
    return state
}
