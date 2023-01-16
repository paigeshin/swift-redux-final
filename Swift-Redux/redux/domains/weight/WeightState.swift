//
//  WeightState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Combine
import Foundation

enum WeightEvent: Equatable {
    case loading
    case createOnMain(Result<Void, GenericError>)
    case updateOnCalendar(Result<Weight, GenericError>)
    case deleteOnCalendar(Result<Weight, GenericError>)
    case deleteOnHistory(Result<Weight, GenericError>)
    case createOnCalendar(Result<Weight, GenericError>)
    case fetchHistory(Result<[Weight], GenericError>)
    case fetchMonthlyWeights(Result<[Weight], GenericError>)
    case fetchCalendarWeekOfYear(Result<[Weight], GenericError>)
    case fetchCalendarMonth(Result<[Weight], GenericError>)
    static func == (lhs: WeightEvent, rhs: WeightEvent) -> Bool {
        switch(lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.createOnMain, .createOnMain):
            return true
        case (.updateOnCalendar, .updateOnCalendar):
            return true
        case (.deleteOnCalendar, .deleteOnCalendar):
            return true
        case (.createOnCalendar, .createOnCalendar):
            return true
        case (.fetchHistory, .fetchHistory):
            return true
        case (.deleteOnHistory, .deleteOnHistory):
            return true
        case (.fetchMonthlyWeights, .fetchMonthlyWeights):
            return true
        case (.fetchCalendarWeekOfYear, .fetchCalendarWeekOfYear):
            return true
        case (.fetchCalendarMonth, .fetchCalendarMonth):
            return true
        default:
            return false
        }
    }
}

struct WeightState: ReduxState {
    var callback: PassthroughSubject<WeightEvent, Never> = PassthroughSubject()
    var monthlyWeights: [Weight] = []
    var dailyWeights: [Weight] = []
    var histories: [Weight] = []
    var unchekcedWeights: [Weight] = []
    var calendarMonthlyWeights: [Weight] = []
    var calendarWeeklyWeights: [Weight] = [] 
    static func == (lhs: WeightState, rhs: WeightState) -> Bool {
        return true
    }
}
