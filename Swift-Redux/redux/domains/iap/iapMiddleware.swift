//
//  iapMiddleware.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import Foundation

struct IAPEnvironment: ReduxEnvironment {
    let iapFetchProductService: IAPFetchProductServiceProtocol
    let iapPurchaseService: IAPPurchaseServiceProtocol
    let iapReceiptValidator: IAPReceiptValidatorProtocol
}

func iapMiddleware(environment: ReduxEnvironment) -> Middleware<AppState, AppAction> {
    let environment: IAPEnvironment = environment as! IAPEnvironment
    let iapFetchProductService: IAPFetchProductServiceProtocol = environment.iapFetchProductService
    let iapPurchaseService: IAPPurchaseServiceProtocol = environment.iapPurchaseService
    let iapReceiptValidator: IAPReceiptValidatorProtocol = environment.iapReceiptValidator
    return { state, action, dispatch in
        switch action {
        case .iap(.async(.fetch)):
            Log.info("🔥🔥🔥 Fetch Products 🔥🔥🔥")
            iapFetchProductService.fetchProducts { state in
                switch state {
                case .success(let products):
                    dispatch(.iap(.set(Array(products))))
                default: break
                }
            }
        case .iap(.async(.buy(let user, let product))):
            state.iapState.callback.send(.loading)
            iapPurchaseService
                .buy(product) { purchaseState in
                    switch purchaseState {
                    case .success:
                        // keychain update
                        Keychain.isSubscribed = true
                        dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
                        state.iapState.callback.send(.buy(.success(())))
                        dispatch(.iap(.async(.validateReceipt(showLoading: false, user))))
                    case .loading:
                        state.iapState.callback.send(.loading)
                    case .error(let error):
                        guard let error: Error = error else {
                            state.iapState.callback.send(.buy(.failure(GenericError(message: "Purchase failed"))))
                            return
                        }
                        state.iapState.callback.send(.buy(.failure(GenericError(error: error))))
                    default: break
                    }
                }
        case .iap(.async(.restore(let user))):
            state.iapState.callback.send(.loading)
            iapPurchaseService
                .restore { restoreState in
                    switch restoreState {
                    case .success:
                        Task {
                            var user: User = user
                            do {
                                let validReceipt: IAPLatestInfo? = try await iapReceiptValidator.validate()
                                guard let latestInfo: IAPLatestInfo = validReceipt else {
                                    Log.info("💵💵💵Subscription Expired💵💵💵")
                                    // keychain update
                                    Keychain.isSubscribed = false
                                    DispatchQueue.main.async {
                                        dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
                                    }
                                    if !user.isSubscribed {
                                        Log.info("💵💵💵If user is already not subscribed, dont update on server again💵💵💵")
                                        DispatchQueue.main.async {
                                            state.iapState.callback.send(.restore(.failure(GenericError(message: "no valid receipt"))))
                                        }
                                        return
                                    }
    
                                    Log.info("💵💵💵If user is not subscribed, update on server💵💵💵")
                                    user.isSubscribed = false
                                    dispatch(.auth(.async(.update(showLoading: false, user))))
                                    DispatchQueue.main.async {
                                        state.iapState.callback.send(.restore(.failure(GenericError(message: "no valid receipt"))))
                                    }
                                    return
                                }

                                Log.info("💵💵💵Subscription is Valid💵💵💵")
                                // keychain update
                                Keychain.isSubscribed = true
                                DispatchQueue.main.async {
                                    dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
                                }

                                // If user already subscribed don't update on server
                                if user.isSubscribed {
                                    Log.info("💵💵💵If user is already subscribed, dont update on server again💵💵💵")
                                    DispatchQueue.main.async {
                                        state.iapState.callback.send(.restore(.success(())))
                                    }
                                    return
                                }

                                Log.info("💵💵💵If user is subscribed, update on server💵💵💵")
                                // server update
                                user.isSubscribed = true
                                user.expiresDate = latestInfo.expires_date
                                if let expiresMilliseconds: Int = Int(latestInfo.expires_date_ms) {
                                    user.expiresMilliSeconds = expiresMilliseconds
                                }
                                dispatch(.auth(.async(.update(showLoading: false, user))))
                                DispatchQueue.main.async {
                                    state.iapState.callback.send(.restore(.success(())))
                                }
                            } catch {
                                Log.error(error)
                                DispatchQueue.main.async {
                                    state.iapState.callback.send(.restore(.failure(GenericError(error: error))))
                                }
                            }
                        }
                    case .loading:
                        state.iapState.callback.send(.loading)
                    case .error(let error):
                        guard let error: Error = error else {
                            state.iapState.callback.send(.restore(.failure(GenericError(message: "Restore failed"))))
                            return
                        }
                        state.iapState.callback.send(.restore(.failure(GenericError(error: error))))
                    default: break
                    }
                }
        case .iap(.async(.validateReceipt(let showLoading, let user))):
            Task {
                var user: User = user
                if showLoading {
                    DispatchQueue.main.async {
                        state.iapState.callback.send(.loading)
                    }
                }
                do {
                    let validReceipt: IAPLatestInfo? = try await iapReceiptValidator.validate()
                    guard let latestInfo: IAPLatestInfo = validReceipt else {
                        Log.info("💵💵💵Subscription Expired💵💵💵")
                        // keychain update
                        Keychain.isSubscribed = false
                        DispatchQueue.main.async {
                            dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
                        }
                        if !user.isSubscribed {
                            Log.info("💵💵💵If user is already not subscribed, dont update on server again💵💵💵")
                            DispatchQueue.main.async {
                                state.iapState.callback.send(.validateReceipt(.success(())))
                            }
                            return
                        }

                        Log.info("💵💵💵If user is not subscribed, update on server💵💵💵")
                        user.isSubscribed = false
                        dispatch(.auth(.async(.update(showLoading: false, user))))
                        DispatchQueue.main.async {
                            state.iapState.callback.send(.validateReceipt(.success(())))
                        }
                        return
                    }

                    Log.info("💵💵💵Subscription is Valid💵💵💵")
                    // keychain update
                    Keychain.isSubscribed = true
                    DispatchQueue.main.async {
                        dispatch(.auth(.setSubscription(Keychain.isSubscribed)))
                    }

                    // If user already subscribed don't update on server
                    if user.isSubscribed {
                        Log.info("💵💵💵If user is already subscribed, dont update on server again💵💵💵")
                        DispatchQueue.main.async {
                            state.iapState.callback.send(.validateReceipt(.success(())))
                        }
                        return
                    }

                    Log.info("💵💵💵If user is subscribed, update on server💵💵💵")
                    // server update
                    user.isSubscribed = true
                    user.expiresDate = latestInfo.expires_date
                    if let expiresMilliseconds: Int = Int(latestInfo.expires_date_ms) {
                        user.expiresMilliSeconds = expiresMilliseconds
                    }
                    dispatch(.auth(.async(.update(showLoading: false, user))))
                    DispatchQueue.main.async {
                        state.iapState.callback.send(.validateReceipt(.success(())))
                    }
                } catch {
                    Log.error(error)
                    DispatchQueue.main.async {
                        state.iapState.callback.send(.validateReceipt(.failure(GenericError(error: error))))
                    }
                }
            }
        default: break
        }
    }
}
