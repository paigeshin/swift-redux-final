//
//  ReminderMessageAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/18.
//

import Foundation

enum ReminderMessageAction: ReduxAction {
    case set([ReminderMessage])
    case clear
    case async(Async)
    enum Async {
        case create(ReminderMessage)
        case setListener(String)
        case clear
        case update(ReminderMessage)
        case delete(ReminderMessage)
        case initialize(String)
    }
    
}
