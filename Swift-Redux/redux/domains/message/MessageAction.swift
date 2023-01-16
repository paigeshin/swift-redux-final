//
//  MessageAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/20.
//

import Foundation

enum MessageAction: ReduxAction {
    case async(Async)
    enum Async {
        case create(Message)
    }
}
