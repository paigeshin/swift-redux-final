//
//  ReminderState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/15.
//

import Combine
import Foundation

enum ReminderEvent: Equatable {
    case loading
    case create(Result<Reminder, GenericError>)
    case update(Result<Reminder, GenericError>)
    case delete(Result<Reminder, GenericError>)
    static func == (lhs: ReminderEvent, rhs: ReminderEvent) -> Bool {
        switch(lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.create, .create):
            return true
        case (.update, .update):
            return true
        case (.delete, .delete):
            return true 
        default:
            return false
        }
    }
}

struct ReminderState: ReduxState {
    var reminders: [Reminder] = []
    var callback: PassthroughSubject<ReminderEvent, Never> = PassthroughSubject()
    static func == (lhs: ReminderState, rhs: ReminderState) -> Bool {
        return true
    }
}
