//
//  reminderMessageMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/18.
//

import Foundation
import Firebase

fileprivate var listener: ListenerRegistration?
fileprivate var isRunningUpdateTask: Bool = false

struct ReminderMessageEnvironment: ReduxEnvironment {
    let reminderMessageRepository: ReminderMessageRepositoryProtocol
}

func reminderMessageMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction>  {
    let reminderMessageEnvironment: ReminderMessageEnvironment = environment as! ReminderMessageEnvironment
    let reminderMessageRepository: ReminderMessageRepositoryProtocol = reminderMessageEnvironment.reminderMessageRepository
    return { state, action, dispatch in
        switch action {
        case .reminderMessage(.async(.create(let message))):
            Task {
                DispatchQueue.main.async {
                    state.reminderMessageState.callback.send(.loading)
                }
                do {
                    let reminderMessage: ReminderMessage = try await reminderMessageRepository.create(reminderMessage: message)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.create(.success(reminderMessage)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.create(.failure(GenericError(error: error))))
                    }
                }
            }
        case .reminderMessage(.async(.setListener(let uid))):
            listener = nil
            listener = reminderMessageRepository
                .subscribe(uid: uid) { reminders, error in
                    if let error: Error = error {
                        Log.error(error)
                        return
                    }
                    dispatch(.reminderMessage(.set(reminders.sorted(by: { $0.updatedAt > $1.updatedAt }))))
                }
        case .reminderMessage(.async(.clear)):
            listener?.remove()
            listener = nil
            dispatch(.reminderMessage(.clear))
        case .reminderMessage(.async(.update(let message))):
            if isRunningUpdateTask {
                Log.info("Update Task is running...")
                return
            }
            isRunningUpdateTask = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRunningUpdateTask = false
            }
            Task {
                DispatchQueue.main.async {
                    state.reminderMessageState.callback.send(.loading)
                }
                do {
                    let reminderMessage: ReminderMessage = try await reminderMessageRepository.update(reminderMessage: message)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.update(.success(reminderMessage)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.update(.failure(GenericError(error: error))))
                    }
                }
            }
        case .reminderMessage(.async(.delete(let message))):
            Task {
                DispatchQueue.main.async {
                    state.reminderMessageState.callback.send(.loading)
                }
                do {
                    let reminderMessage: ReminderMessage = try await reminderMessageRepository
                        .delete(reminderMessage: message)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.delete(.success(reminderMessage)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderMessageState.callback.send(.delete(.failure(GenericError(error: error))))
                    }
                }
                
            }
        case .reminderMessage(.async(.initialize(let uid))):
            Config
                .reminderDefaultMessages
                .forEach { message in
                    Task {
                        do {
                            _ = try await reminderMessageRepository
                                .create(reminderMessage: ReminderMessage(
                                    id: UUID().uuidString,
                                    uid: uid,
                                    message: message,
                                    createdAt: Date(),
                                    updatedAt: Date(),
                                    isDefault: true))
                        } catch {
                            Log.error(error)
                        }
                    }
                }
        default: break
        }
    }
}
