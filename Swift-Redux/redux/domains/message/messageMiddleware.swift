//
//  messageMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/20.
//

import Foundation

struct MessageEnvironment: ReduxEnvironment {
    let messageRepository: MessageRepositoryProtocol
}

func messageMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let environment: MessageEnvironment = environment as! MessageEnvironment
    let messageRepository: MessageRepositoryProtocol = environment.messageRepository
    return { state, action, dispatch in
        switch action {
        case .message(.async(.create(let message))):
            Task {
                DispatchQueue.main.async {
                    state.messageState.callback.send(.loading)
                }
                do {
                    let _ = try await messageRepository.create(message: message)
                    DispatchQueue.main.async {
                        state.messageState.callback.send(.create(.success(message)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.messageState.callback.send(.create(.failure(GenericError(error: error))))
                    }
                }
            }
        default: break
        }
    }
}
