//
//  AuthState.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/17.
//

import Combine
import Foundation
import FirebaseFirestore

enum AuthEvent: Equatable {
    case loading
    case signin(Result<User, GenericError>)
    case linkAnonymous(Result<User, GenericError>)
    case fetch(Result<User, GenericError>)
    case signout(Result<Void, GenericError>)
    case update(Result<Void, GenericError>)
    case delete(Result<Void, GenericError>)
    static func == (lhs: AuthEvent, rhs: AuthEvent) -> Bool {
        switch(lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.signin, .signin):
            return true
        case (.linkAnonymous, .linkAnonymous):
            return true
        case (.fetch, .fetch):
            return true
        case (.signout, .signout):
            return true
        case (.update, .update):
            return true
        case (.delete, .delete):
            return true 
        default:
            return false 
        }
    }
}

struct AuthState: ReduxState {
    var user: User?
    var userSignedInPreviosuly: Bool = false
    var isSubscribed: Bool = false
    var recentlyLoggedIn: Bool = false 
    var callback: PassthroughSubject<AuthEvent, Never> = PassthroughSubject()
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        return lhs.user == rhs.user && lhs.userSignedInPreviosuly == rhs.userSignedInPreviosuly
    }
}
