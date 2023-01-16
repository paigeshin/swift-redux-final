//
//  healthkitMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/24.
//

import Foundation

struct HealthkitEnvironment: ReduxEnvironment {
    let healthstore: HealthKitStoreProtocol
}

func healthstoreMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let environment: HealthkitEnvironment = environment as! HealthkitEnvironment
    let healthstore: HealthKitStoreProtocol = environment.healthstore
    return { state, action, dispatch in
        switch action {
        case .healthkit(.async(.create(let weight))):
            Task {
                do {
                    let success: Bool = try await healthstore.write(weight: weight)
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.create(.success(success)))
                    }
                } catch {
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.create(.failure(GenericError(error: error))))
                    }
                    Log.error(error)
                }
            }
        case .healthkit(.async(.request)):
            Task {
                do {
                    let success: Bool = try await healthstore.request()
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.request(.success(success)))
                    }
                } catch {
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.request(.failure(GenericError(error: error))))
                    }
                }
            }
        case .healthkit(.async(.delete(let weight))):
            Task {
                do {
                    let success: Bool = try await healthstore.delete(weight: weight)
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.delete(.success(success)))
                    }
                } catch {
                    DispatchQueue.main.async {
                        state.healthkitState.callback.send(.delete(.failure(GenericError(error: error))))
                    }
                }
            }
        default: break
        }
    }
}
