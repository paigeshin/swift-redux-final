//
//  logMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/09.
//

import Foundation

func logMiddleware() -> Middleware<AppState, AppAction> {
    return { state, action, dispatch in
        Log.info("⭐️⭐️⭐️\(action)⭐️⭐️⭐️")
    }
}
