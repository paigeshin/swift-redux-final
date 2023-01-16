//
//  ReminderState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/18.
//

import Foundation
import Combine

enum ReminderMessageEvent: Equatable {
    case loading
    case create(Result<ReminderMessage, GenericError>)
    case update(Result<ReminderMessage, GenericError>)
    case delete(Result<ReminderMessage, GenericError>)
    static func == (lhs: ReminderMessageEvent, rhs: ReminderMessageEvent) -> Bool {
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

struct ReminderMessageState: ReduxState {
    var reminderMessages: [ReminderMessage] = []
    var callback: PassthroughSubject<ReminderMessageEvent, Never> = PassthroughSubject()
    static func == (lhs: ReminderMessageState, rhs: ReminderMessageState) -> Bool {
        return true
    }
}
