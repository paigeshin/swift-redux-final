//
//  WeightAction.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation

enum WeightAction: ReduxAction {
    case async(Async)
    case setMonthlyWeights([Weight])
    case setDailyWeights(day: Date)
    case createCalendarWeight(Weight)
    case updateCalendarWeight(Weight)
    case appendHistories([Weight])
    case deleteHistory(Weight)
    case deleteDailyWeight(Weight)
    case setUncheckedWeights([Weight])
    case setCalendarWeeklyWeights([Weight])
    case setCalendarMonthlyWeights([Weight])
    case clearHistory
    case clear 
    enum Async {
        case createOnMain(User, Double, WeightMetric)
        case createOnCalendar(Weight)
        case deleteOnCalendar(Weight)
        case checkOnCalendar(Weight)
        case deleteOnHistory(Weight)
        case fetchMonthlyWeight(uid: String, year: Int, month: Int)
        case fetchHistory(uid: String, lastDocumentDate: Date?, limit: Int)
        case fetchCalendarWeekOfYear(uid: String, year: Int, weekOfYear: Int)
        case fetchCalendarMonth(uid: String, year: Int, month: Int)
        case setUncheckedWeightsListener(uid: String)
        case clear
    }
    
}

