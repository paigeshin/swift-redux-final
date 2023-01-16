//
//  AppAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/10.
//

import Foundation

enum AppAction: ReduxAction {
    case navigate(Route)
    case auth(AuthAction)
    case weight(WeightAction)
    case iap(IAPAction)
    case reminder(ReminderAction)
    case reminderMessage(ReminderMessageAction)
    case message(MessageAction)
    case healthkit(HealthkitAction)
}

