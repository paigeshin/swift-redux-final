//
//  authMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/21.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

fileprivate var userListener: ListenerRegistration?

struct AuthEnvironment: ReduxEnvironment {
    let authService: AuthServiceProtocol
    let userRepository: UserRepositoryProtocol
    let googleAuth: GoogleAuthProtocol
    let appleAuth: AppleAuthProtocol
    let reminderRepository: ReminderRepositoryProtocol
}

func authMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let environment: AuthEnvironment = environment as! AuthEnvironment
    let appleAuth: AppleAuthProtocol = environment.appleAuth
    let googleAuth: GoogleAuthProtocol = environment.googleAuth
    let authService: AuthServiceProtocol = environment.authService
    let userRepository: UserRepositoryProtocol = environment.userRepository
    return { state, action, dispatch in
        
        @Sendable func clear() {
            try? authService.forceSignOut()
            userListener?.remove()
            userListener = nil
            dispatch(.auth(.clear))
            dispatch(.reminder(.async(.clear)))
            dispatch(.reminderMessage(.async(.clear)))
            dispatch(.weight(.async(.clear)))
        }
        
        @Sendable func initialize(user: User) {
            dispatch(.auth(.set(user)))
            dispatch(.auth(.async(.setListener(uid: user.uid))))
            Keychain.userSignedInPreviously = true
            dispatch(.auth(.setUserSignedInPreviosuly(Keychain.userSignedInPreviously)))
            dispatch(.iap(.async(.validateReceipt(showLoading: false, user))))
            dispatch(.reminder(.async(.setListener(user.uid))))
            dispatch(.reminderMessage(.async(.setListener(user.uid))))
            dispatch(.weight(.async(.setUncheckedWeightsListener(uid: user.uid))))
        }
        
        switch action {
        case .auth(.async(.initialize)):
            dispatch(.auth(.setUserSignedInPreviosuly(Keychain.userSignedInPreviously)))
            dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
        case .auth(.async(.requestAppleSignIn(let request))):
            state.authState.callback.send(.loading)
            appleAuth.handleRequest(request: request)
        case .auth(.async(.signInWithApple(let result))):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                do {
                    guard let result: AppleAuthResult = appleAuth.authResult(result: result) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.signin(.failure(GenericError(message: "AppleAuthResult is nil"))))
                            clear()
                        }
                        return
                    }
                    guard let authDataResult: AuthDataResult = try await authService.signIn(idToken: result.identityToken, currentNonce: result.currentNonce) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.signin(.failure(GenericError(message: "AuthDataResult is nil"))))
                            
                        }
                        return
                    }
                    guard let existingUser: User = try await userRepository.fetch(uid: authDataResult.user.uid) else {
                        Log.info("User does not exist! Create a new user!")
                        let newUser: User = User(id: authDataResult.user.uid,
                                                 uid: authDataResult.user.uid,
                                                 name: result.appleIdCredentials.fullName?.givenName,
                                                 providers: [authDataResult.credential?.provider ?? ""],
                                                 isAnonymous: authDataResult.user.isAnonymous,
                                                 isActive: true,
                                                 isSubscribed: false,
                                                 createdAt: Date(),
                                                 updatedAt: Date())
                        let reminder: Reminder = Reminder.makeDefaultReminder(id: UUID().uuidString, uid: authDataResult.user.uid)
                        let createdUser: User = try await userRepository.create(user: newUser)
                        DispatchQueue.main.async {
                            dispatch(.reminder(.async(.create(reminder))))
                            dispatch(.reminderMessage(.async(.initialize(newUser.uid))))
                            state.authState.callback.send(.signin(.success(createdUser)))
                            initialize(user: createdUser)
                        }
                        return
                    }
                    Log.info("User already exists!")
                            
                    if let provider: String = authDataResult.credential?.provider,
                        !existingUser.providers.contains(provider) {
                        Log.info("New Provider Detected, Update User!")
                       var updateUser: User = existingUser
                       updateUser.providers.append(provider)
                       if updateUser.name == nil {
                           updateUser.name = result.appleIdCredentials.fullName?.givenName
                       }
                       let updatedUser: User = try await userRepository.update(user: updateUser)
                       DispatchQueue.main.async {
                           state.authState.callback.send(.signin(.success(updatedUser)))
                           initialize(user: updatedUser)
                       }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signin(.success(existingUser)))
                        initialize(user: existingUser)
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signin(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.signInWithGoogle)):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                do {
                    guard let result: GoogleAuthResult = try await googleAuth.signIn() else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.signin(.failure(GenericError(message: "Google Auth Result is nil"))))
                            clear()
                        }
                        return
                    }
                    guard let authDataResult: AuthDataResult = try await authService.signIn(idToken: result.idToken, accessToken: result.accessToken) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.signin(.failure(GenericError(message: "AuthDataResult is nil"))))
                            clear()
                        }
                        return
                    }
                    guard let existingUser: User = try await userRepository.fetch(uid: authDataResult.user.uid) else {
                        Log.info("User does not exist! Create a new user!")
                        let newUser: User = User(id: authDataResult.user.uid,
                                                 uid: authDataResult.user.uid,
                                                 name: authDataResult.user.displayName,
                                                 providers: [authDataResult.credential?.provider ?? ""],
                                                 isAnonymous: authDataResult.user.isAnonymous,
                                                 isActive: true,
                                                 isSubscribed: false,
                                                 createdAt: Date(),
                                                 updatedAt: Date())
                        let reminder: Reminder = Reminder.makeDefaultReminder(id: UUID().uuidString, uid: authDataResult.user.uid)
                        let createdUser: User = try await userRepository.create(user: newUser)
                        DispatchQueue.main.async {
                            dispatch(.reminder(.async(.create(reminder))))
                            dispatch(.reminderMessage(.async(.initialize(newUser.uid))))
                            state.authState.callback.send(.signin(.success(createdUser)))
                            initialize(user: createdUser)
                        }
                        return
                    }
                    Log.info("User already exists!")
                            
                    if let provider: String = authDataResult.credential?.provider,
                        !existingUser.providers.contains(provider) {
                        Log.info("New Provider Detected, Update User!")
                       var updateUser: User = existingUser
                       updateUser.providers.append(provider)
                       if updateUser.name == nil {
                           updateUser.name = authDataResult.user.displayName
                       }
                       let updatedUser: User = try await userRepository.update(user: updateUser)
                       DispatchQueue.main.async {
                           state.authState.callback.send(.signin(.success(updatedUser)))
                           initialize(user: updatedUser)
                       }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signin(.success(existingUser)))
                        initialize(user: existingUser)
                    }
                } catch {
                    Log.error(error)
                    authService.signOutFromGoogle()
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signin(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.linkAnonymousUserWithApple(let result, let user))):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                guard let appleAuthResult: AppleAuthResult = appleAuth.authResult(result: result) else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "AppleAuthResult is nil"))))
                        clear()
                    }
                    return
                }
                guard let firebaseUser: FirebaseUser = authService.currentUser else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "Firebase user is nil"))))
                        clear()
                    }
                    return
                }
                do {
                    let crendential = OAuthProvider.credential(withProviderID: "apple.com", idToken: appleAuthResult.identityToken, rawNonce: appleAuthResult.currentNonce)
                    guard let authDataResult: AuthDataResult = try await authService.linkAnonymousUser(user: firebaseUser, credential: crendential) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "AuthDataResult is nil"))))
                            clear()
                        }
                        return
                    }
                    var linkedUser: User = user
                    if let credential: AuthCredential = authDataResult.credential,
                        !linkedUser.providers.contains(credential.provider) {
                        linkedUser.providers.append(credential.provider)
                    }
                    linkedUser.isAnonymous = false
                    linkedUser.name = appleAuthResult.appleIdCredentials.fullName?.givenName
                    let updatedUser: User = try await userRepository.update(user: linkedUser)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.success((updatedUser))))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(error: error))))
                        clear()
                    }
                }
                
            }
        case .auth(.async(.linkAnonymousUserWithGoogle(let user))):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                guard let firebaseUser: FirebaseUser = authService.currentUser else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "Firebase user is nil"))))
                        clear()
                    }
                    return
                }
                guard let googleAuthResult: GoogleAuthResult = try await googleAuth.signIn() else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "GoogleAuthResult is nil"))))
                        clear()
                    }
                    return
                }
                let credential: AuthCredential = GoogleAuthProvider.credential(withIDToken: googleAuthResult.idToken, accessToken: googleAuthResult.accessToken)
                do {
                    guard let authDataResult: AuthDataResult = try await authService.linkAnonymousUser(user: firebaseUser, credential: credential) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "AuthDataResult is nil"))))
                            clear()
                        }
                        return
                    }
                    var linkedUser: User = user
                    if let credential: AuthCredential = authDataResult.credential,
                        !linkedUser.providers.contains(credential.provider) {
                        linkedUser.providers.append(credential.provider)
                    }
                    linkedUser.isAnonymous = false
                    linkedUser.name = authDataResult.user.displayName
                    let updatedUser: User = try await userRepository.update(user: linkedUser)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.success((updatedUser))))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.signInAnonymously)):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                guard let authDataResult: AuthDataResult = try await authService.signInAnonymously() else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.linkAnonymous(.failure(GenericError(message: "AuthDataResult is nil"))))
                        clear()
                    }
                    return
                }
                do {
                    let newUser: User = User(id: authDataResult.user.uid,
                                             uid: authDataResult.user.uid,
                                             providers: [authDataResult.credential?.provider ?? ""],
                                             isAnonymous: authDataResult.user.isAnonymous,
                                             isActive: true,
                                             isSubscribed: false,
                                             createdAt: Date(),
                                             updatedAt: Date())
                    let reminder: Reminder = Reminder.makeDefaultReminder(id: UUID().uuidString, uid: authDataResult.user.uid)
                    let createdUser: User = try await userRepository.create(user: newUser)
                    DispatchQueue.main.async {
                        dispatch(.reminder(.async(.create(reminder))))
                        dispatch(.reminderMessage(.async(.initialize(newUser.uid))))
                        state.authState.callback.send(.signin(.success(createdUser)))
                        initialize(user: createdUser)
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signin(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.setListener(let uid))):
            userListener?.remove()
            userListener = nil
            userListener = userRepository
                .subscribe(uid: uid) { user, error in
                    if let error: Error {
                        Log.error(error)
                    }
                    if let user: User = user, authService.currentUser != nil {
                        dispatch(.auth(.set(user)))
                    }
                }
        case .auth(.async(.fetch)):
            Task {
                guard let firebaseUser: FirebaseUser = authService.currentUser else {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.fetch(.failure(GenericError(message: "Firebase User is nil"))))
                        clear()
                    }
                    return
                }
                do {
                    guard let user: User = try await userRepository.fetch(uid: firebaseUser.uid) else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.fetch(.failure(GenericError(message: "User is nil"))))
                            clear()
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        state.authState.callback.send(.fetch(.success(user)))
                        initialize(user: user)
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.fetch(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.signout)):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                do {
                    try await authService.signOut()
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signout(.success(())))
                        clear()
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.signout(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.update(let showLoading, let user))):
            Task {
                if showLoading {
                    DispatchQueue.main.async {
                        state.authState.callback.send(.loading)
                    }
                }
                do {
                    let updatedUser: User = try await userRepository.update(user: user)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.update(.success(())))
                        initialize(user: updatedUser)
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.update(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        case .auth(.async(.delete(let user))):
            Task {
                DispatchQueue.main.async {
                    state.authState.callback.send(.loading)
                }
                do {
                    guard let firebaseUser: FirebaseUser = authService.currentUser else {
                        DispatchQueue.main.async {
                            state.authState.callback.send(.delete(.failure(GenericError(message: "firebase user is nil"))))
                            clear()
                        }
                        return
                    }
                    var deletedUser: User = user
                    deletedUser.isActive = false
                    _ = try await userRepository.update(user: deletedUser)
                    _ = try await authService.delete(user: firebaseUser)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.delete(.success(())))
                        clear()
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.authState.callback.send(.delete(.failure(GenericError(error: error))))
                        clear()
                    }
                }
            }
        default: break
        }
    }
    
}
