//
//  AuthActions.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/17.
//

import Foundation
import AuthenticationServices

enum AuthAction: ReduxAction {
    case set(User)
    case setUserSignedInPreviosuly(Bool)
    case setSubscription(Bool)
    case setRecentlyLoggedIn(Bool)
    case clear 
    
    case async(Async)    
    enum Async {
        case requestAppleSignIn(ASAuthorizationAppleIDRequest)
        case setListener(uid: String)
        case signInWithApple(Result<ASAuthorization, Error>)
        case signInWithGoogle
        case signInAnonymously
        case fetch
        case signout
        case linkAnonymousUserWithApple(Result<ASAuthorization, Error>, User)
        case linkAnonymousUserWithGoogle(User)
        case update(showLoading: Bool, User)
        case initialize
        case delete(User)
    }
    
}

