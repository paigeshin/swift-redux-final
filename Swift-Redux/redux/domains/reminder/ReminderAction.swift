//
//  ReminderAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/15.
//

import Foundation

enum ReminderAction: ReduxAction {
    case set([Reminder])
    case clear 
    case async(Async)
    enum Async {
        case create(Reminder)
        case setListener(String)
        case clear
        case update(Reminder)
        case delete(Reminder)
    }
    
}
