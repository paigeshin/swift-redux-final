//
//  reminderMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/15.
//

import Foundation
import Firebase

fileprivate var listener: ListenerRegistration?

struct ReminderEnvironment: ReduxEnvironment {
    let reminderRepository: ReminderRepositoryProtocol
    let notificationController: NotificationControllerProtocol
}

func reminderMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let reminderEnvironment: ReminderEnvironment = environment as! ReminderEnvironment
    let reminderRepository: ReminderRepositoryProtocol = reminderEnvironment.reminderRepository
    let notificationController: NotificationControllerProtocol = reminderEnvironment.notificationController
    return { state, action, dispatch in
        switch action {
        case .reminder(.async(.create(let reminder))):
            state.reminderState.callback.send(.loading)
            Task {
                DispatchQueue.main.async {
                    state.reminderState.callback.send(.loading)
                }
                do {
                    let reminder: Reminder = try await reminderRepository.create(reminder: reminder)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.create(.success(reminder)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.create(.failure(GenericError(error: error))))
                    }
                }
                
            }
        case .reminder(.async(.setListener(let uid))):
            listener = nil
            listener = reminderRepository
                .subscribe(uid: uid) { reminders, error in
                    if let error: Error = error {
                        Log.error(error)
                        return
                    }
                    dispatch(.reminder(.set(reminders)))
                    notificationController.initializeNotification(reminders: reminders)
                }
        case .reminder(.async(.clear)):
            listener?.remove()
            listener = nil
            dispatch(.reminder(.clear))
        case .reminder(.async(.update(let reminder))):
            Task {
                DispatchQueue.main.async {
                    state.reminderState.callback.send(.loading)
                }
                do {
                    let reminder: Reminder = try await reminderRepository.update(reminder: reminder)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.update(.success(reminder)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.update(.failure(GenericError(error: error))))
                    }
                }
            }
        case .reminder(.async(.delete(let reminder))):
            Task {
                DispatchQueue.main.async {
                    state.reminderState.callback.send(.loading)
                }
                do {
                    let reminder: Reminder = try await reminderRepository.delete(reminder: reminder)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.delete(.success(reminder)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.reminderState.callback.send(.delete(.failure(GenericError(error: error))))
                    }
                    
                }
            }
        default: break 
        }
    }
}
