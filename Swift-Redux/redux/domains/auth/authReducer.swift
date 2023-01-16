//
//  authReducer.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/17.
//

import Foundation

func authReducer(_ state: AuthState, _ action: AuthAction) -> AuthState {
    var state: AuthState = state
    switch action {
    case .set(let user):
        state.user = user
    case .clear:
        state.user = nil
    case .setUserSignedInPreviosuly(let signedIn):
        state.userSignedInPreviosuly = signedIn
    case .setSubscription(let subscribed):
        state.isSubscribed = subscribed
    case .setRecentlyLoggedIn(let recentLoggedIn):
        state.recentlyLoggedIn = recentLoggedIn
    default: break 
    }
    
    return state
}

