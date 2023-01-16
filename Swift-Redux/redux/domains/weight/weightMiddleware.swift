//
//  weightMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation
import Firebase

fileprivate var uncheckedWeightsListener: ListenerRegistration?

struct WeightEnvironment: ReduxEnvironment {
    let weightRepository: WeightRepositoryProtocol
    let userRepository: UserRepositoryProtocol
}

func weightMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let environment: WeightEnvironment = environment as! WeightEnvironment
    let weightRepository: WeightRepositoryProtocol = environment.weightRepository
    return { state, action, dispatch in
        switch action {
        case .weight(.async(.createOnMain(let user, let kg, let weightMetric))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                
                var user: User = user
                let date: Date = Date()
                let year: Int = Calendar.current.component(.year, from: date)
                let month: Int = Calendar.current.component(.month, from: date)
                let day: Int = Calendar.current.component(.day, from: date)
                let kg: Double = kg
                let goalKilogram: Double = user.goalKilogram ?? 0 
                guard let goal: Goal = user.goal,
                      let startKG: Double = user.startKilogram,
                      let centimeter: Double = user.centimeter
                else {
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.createOnMain(.failure(GenericError(message: "User doesn't have sufficient data to create weight"))))
                    }
                    return
                }
                let weekOfYear: Int = Calendar.current.component(.weekOfYear, from: date)
                let weekday: Int = Calendar.current.component(.weekday, from: date)
                        
                let weight: Weight = Weight(id: UUID().uuidString,
                                            uid: user.uid,
                                            goalKilogram: goalKilogram,
                                            kilogram: kg,
                                            goal: goal,
                                            startKilogram: startKG,
                                            centimeter: centimeter,
                                            date: date,
                                            isChecked: false,
                                            year: year,
                                            month: month,
                                            day: day,
                                            weekOfYear: weekOfYear,
                                            weekday: weekday)
                do {
                    let weight: Weight = try await weightRepository.create(weight: weight)
                    user.kilogram = weight.kilogram
                    user.weightMetric = weightMetric
                    dispatch(.auth(.async(.update(showLoading: false, user))))
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.createOnMain(.success(())))
                    }
                    dispatch(.healthkit(.async(.create(weight))))
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.createOnMain(.failure(GenericError(error: error))))
                    }
                }
            }

        case .weight(.async(.fetchMonthlyWeight(let uid, let year, let month))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                do {
                    let weights: [Weight] = try await weightRepository.fetch(uid: uid, year: year, month: month)
                    dispatch(.weight(.setMonthlyWeights(weights)))
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchMonthlyWeights(.success(weights)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchMonthlyWeights(.failure(GenericError(error: error))))
                    }
                }
                
            }
            
      
        case .weight(.async(.deleteOnCalendar(let weight))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                do {
                    let weight: Weight = try await weightRepository.delete(weight: weight)
                    dispatch(.weight(.deleteDailyWeight(weight)))
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.deleteOnCalendar(.success(weight)))
                        dispatch(.healthkit(.async(.delete(weight))))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.deleteOnCalendar(.failure(GenericError(error: error))))
                    }
                }
            }
        case .weight(.async(.checkOnCalendar(let weight))):
            if weight.isChecked {
                state.weightState.callback.send(.updateOnCalendar(.success(weight)))
                return
            }
            Task {
                var weight: Weight = weight
                weight.isChecked = true
                do {
                    let weight: Weight = try await weightRepository.update(weight: weight)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.updateOnCalendar(.success(weight)))
                        dispatch(.weight(.updateCalendarWeight(weight)))
                        dispatch(.weight(.setDailyWeights(day: weight.date)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.updateOnCalendar(.failure(GenericError(error: error))))
                    }
                }
            }
        case .weight(.async(.createOnCalendar(let weight))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                do {
                    let weight: Weight = try await weightRepository.create(weight: weight)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.createOnCalendar(.success(weight)))
                        dispatch(.weight(.createCalendarWeight(weight)))
                        dispatch(.weight(.setDailyWeights(day: weight.date)))
                        dispatch(.healthkit(.async(.create(weight))))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.createOnCalendar(.failure(GenericError(error: error))))
                    }
                }
            }
        case .weight(.async(.fetchHistory(let uid, let lastDocumentDate, let limit))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                do {
                    let weights: [Weight] = try await weightRepository.fetch(uid: uid, lastDocumentDate: lastDocumentDate, limit: limit)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchHistory(.success(weights)))
                        dispatch(.weight(.appendHistories(weights)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchHistory(.failure(GenericError(error: error))))
                    }
                }
            }
        case .weight(.async(.deleteOnHistory(let weight))):
            Task {
                DispatchQueue.main.async {
                    state.weightState.callback.send(.loading)
                }
                do {
                    let weight: Weight = try await weightRepository.delete(weight: weight)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.deleteOnHistory(.success(weight)))
                        dispatch(.weight(.deleteHistory(weight)))
                        dispatch(.healthkit(.async(.delete(weight))))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.deleteOnHistory(.failure(GenericError(error: error))))
                    }
                }
            }
        case .weight(.async(.setUncheckedWeightsListener(let uid))):
            uncheckedWeightsListener = nil
            uncheckedWeightsListener = weightRepository.subscribe(uid: uid,
                                                                  key: NetworkWeight.QueryKey.isChecked.rawValue,
                                                                  value: false, observer: { weights, error in
                if let error: Error = error {
                    Log.error(error)
                    return
                }
                dispatch(.weight(.setUncheckedWeights(weights)))
            })
        case .weight(.async(.clear)):
            uncheckedWeightsListener?.remove()
            uncheckedWeightsListener = nil
            dispatch(.weight(.clear))
        case .weight(.async(.fetchCalendarMonth(let uid, let year, let month))):
            DispatchQueue.main.async {
                state.weightState.callback.send(.loading)
            }
            Task {
                do {
                    let weights: [Weight] = try await weightRepository.fetch(uid: uid, year: year, month: month)
                    DispatchQueue.main.async {
                        dispatch(.weight(.setCalendarMonthlyWeights(weights)))
                        state.weightState.callback.send(.fetchCalendarMonth(.success(weights)))
                    }
                    Log.info("Monthly Weights: => \(weights)")
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchCalendarMonth(.failure(GenericError(error: error))))
                    }
                }
            }

        case .weight(.async(.fetchCalendarWeekOfYear(let uid, let year, let weekOfYear))):
            DispatchQueue.main.async {
                state.weightState.callback.send(.loading)
            }
            Task {
                do {
                    let weights: [Weight] = try await weightRepository.fetch(uid: uid, year: year, weekOfYear: weekOfYear)
                    DispatchQueue.main.async {
                        dispatch(.weight(.setCalendarWeeklyWeights(weights)))
                        state.weightState.callback.send(.fetchCalendarWeekOfYear(.success(weights)))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.weightState.callback.send(.fetchCalendarWeekOfYear(.failure(GenericError(error: error))))
                    }
                }
            }
        default: break
        }
    }
}
