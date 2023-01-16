//
//  App.swift
//  WeightReminder
//
//  Created by paige shin on 2022/11/09.
//

import Foundation

typealias Dispatcher<Action: ReduxAction> = (Action) -> Void
typealias Reducer<State: ReduxState, Action: ReduxAction> = (_ state: State, _ action: Action) -> State
typealias Middleware<State: ReduxState, Action: ReduxAction> = (State, Action, @escaping Dispatcher<Action>) -> Void

protocol ReduxState: Equatable { }
protocol ReduxAction { }
protocol ReduxEnvironment { }

final class Store<State: ReduxState, Action: ReduxAction>: ObservableObject {

    @Published var state: State
    private let reducer: Reducer<State, Action>
    private var middlewares: [Middleware<State, Action>]

    init(state: State,
         reducer: @escaping Reducer<State, Action>,
         middlewares: [Middleware<State, Action>] = []) {
        self.reducer = reducer
        self.state = state
        self.middlewares = middlewares
    }

    func dispatch(action: Action) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.state = strongSelf.reducer(strongSelf.state, action)
        }

        // run all middlewares
        self.middlewares.forEach { [weak self] middleware in
            guard let strongSelf = self else { return }
            middleware(strongSelf.state, action, strongSelf.dispatch)
        }
        
    }
    
    func inject(middlewares: [Middleware<State, Action>]) {
        self.middlewares = middlewares
    }

}
