//
//  weightReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation

func weightReducer(_ state: WeightState, _ action: WeightAction) -> WeightState {
    var state: WeightState = state
    switch action {
    case .setCalendarWeeklyWeights(let weights):
        state.calendarWeeklyWeights = weights
    case .setCalendarMonthlyWeights(let weights):
        state.calendarMonthlyWeights = weights
    case .setMonthlyWeights(let weights):
        state.monthlyWeights = weights
    case .setDailyWeights(let day):
        let year: Int = Calendar.current.component(.year, from: day)
        let month: Int = Calendar.current.component(.month, from: day)
        let day: Int = Calendar.current.component(.day, from: day)
        state.dailyWeights = state.monthlyWeights
            .filter {
                $0.year == year && $0.month == month && $0.day == day
            }
            .sorted(by: { $0.date > $1.date })
    case .deleteDailyWeight(let weight):
        state.dailyWeights.removeAll(where: { $0.id == weight.id })
        state.monthlyWeights.removeAll(where: { $0.id == weight.id })
    case .appendHistories(let weights):
        weights.forEach { weight in
            if !state.histories.contains(where: { $0.id == weight.id }) {
                state.histories.append(weight)
            }
        }
    case .deleteHistory(let weight):
        guard let index: Int = state.histories.firstIndex(where: { $0.id == weight.id }) else {
            return state
        }
        Log.info("❌❌❌DELETE HISTORY AT \(index)❌❌❌")
        Log.info("Weight: \(state.histories[index])")
        state.histories.remove(at: index)
        state.dailyWeights.removeAll(where: { $0.id == weight.id })
        state.monthlyWeights.removeAll(where: { $0.id == weight.id })
    case .setUncheckedWeights(let weights):
        state.unchekcedWeights = weights
    case .createCalendarWeight(let weight):
        if !state.monthlyWeights.contains(where: { $0.id == weight.id }) {
            state.monthlyWeights.append(weight)
        }
    case .updateCalendarWeight(let weight):
        guard let monthlyWeightIndex: Int = state.monthlyWeights.firstIndex(where: { $0.id == weight.id }) else {
            return state
        }
        state.monthlyWeights[monthlyWeightIndex] = weight
        guard let dailyWeightIndex: Int = state.dailyWeights.firstIndex(where: { $0.id == weight.id }) else {
            return state
        }
        state.dailyWeights[dailyWeightIndex] = weight
    case .clearHistory:
        state.histories = [] 
    case .clear:
        state.unchekcedWeights = []
        state.histories = []
        state.monthlyWeights = []
        state.dailyWeights = [] 
    default: break 
    }
    return state
}
