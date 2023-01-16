//
//  MessageState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/20.
//

import Foundation
import Combine

enum MessageEvent: Equatable {
    case loading
    case create(Result<Message, GenericError>)
    static func == (lhs: MessageEvent, rhs: MessageEvent) -> Bool {
        switch(lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.create, .create):
            return true
        default:
            return false
        }
    }
}

struct MesssageState: ReduxState {
    var callback: PassthroughSubject<MessageEvent, Never> = PassthroughSubject()
    static func == (lhs: MesssageState, rhs: MesssageState) -> Bool {
        return true
    }
}
