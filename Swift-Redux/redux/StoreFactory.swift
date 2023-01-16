//
//  StoreFactory.swift
//  WeightReminder
//
//  Created by paige shin on 2022/12/13.
//

import SwiftUI

struct StoreFactory {
    
    static func makeStore() -> Store<AppState, AppAction> {
        return Store<AppState, AppAction>(state: AppState(), reducer: appReducer, middlewares: [])
    }
    
    static func injectMiddlewares(store: Store<AppState, AppAction>) {
        let windonScene: UIWindowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let rootViewController: UIViewController = windonScene.windows.first!.rootViewController!
        store.inject(middlewares: [
            logMiddleware(),
            authMiddleware(
                environment: AuthEnvironment(
                    authService: AuthService(),
                    userRepository: UserRepository(remoteDataSource: UserRemoteDataSource()),
                    googleAuth: GoogleAuth(rootViewController: rootViewController),
                    appleAuth: AppleAuth(),
                    reminderRepository: ReminderRepository(remoteDataSource: ReminderRemoteDataSource())
                )
            ),
            weightMiddleware(environment:
                                WeightEnvironment(
                                    weightRepository: WeightRepository(remoteDataSource: WeightRemoteDataSource()),
                                    userRepository: UserRepository(remoteDataSource: UserRemoteDataSource())
                                )
                            ),
            iapMiddleware(environment:
                            IAPEnvironment(
                                iapFetchProductService: IAPFetchProductService(productIdentifiers: Set(Config.productsIds)),
                                iapPurchaseService: IAPPurchaseService(),
                                iapReceiptValidator: IAPReceiptValidator(iapFetchReceiptService: IAPFetchReciptService(sharedSecret: Config.sharedSecrent)))
                         ),
            reminderMiddleware(environment:
                                ReminderEnvironment(
                                    reminderRepository: ReminderRepository(remoteDataSource: ReminderRemoteDataSource()),
                                    notificationController: NotificationController()
                                )
                              ),
            reminderMessageMiddleware(environment:
                                        ReminderMessageEnvironment(reminderMessageRepository: ReminderMessageRepository(remoteDataSource: ReminderMessageRemoteDataSource()))
                                     ),
            messageMiddleware(environment:
                                MessageEnvironment(messageRepository: MessageRepository(remoteDataSource: MessageRemoteDataSource()))
                             ),
            healthstoreMiddleware(environment:
                                    HealthkitEnvironment(
                                        healthstore: HealthKitStore(
                                            weightCalculator: WeightCalculator(),
                                            heightCalculator: HeightCalculator(),
                                            bmiCalculator: BMICalculator())
                                    )
                                 )
        ])
    }
    
}
