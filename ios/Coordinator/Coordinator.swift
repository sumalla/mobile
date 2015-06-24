/*
The MIT License (MIT)

Copyright (c) 2015 Cameron Pulsford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation

public class CoordinatorReference<StateType: Equatable> {

    public private(set) var currentState: StateType
    private var _previousStates = [StateType]()
    
    public var previousState: StateType? {
        return _previousStates.last
    }
    
    public func previousStates() -> [StateType] {
        return _previousStates
    }

    private init(initialState: StateType) {
        currentState = initialState
    }

    public func canTransitionToState(newState: StateType) -> Bool {
        fatalError("implement")
    }

    public func transitionToState(newState: StateType) {
        fatalError("implement")
    }

    public func canTransitionBack() -> Bool {
        fatalError("implement")
    }

    public func transitionBack() {
        fatalError("implement")
    }
    
    public func unload() {
        fatalError("implement")
    }

}

public protocol CoordinatorManager: class {

    typealias StateType: Equatable

    weak var coordinator: CoordinatorReference<StateType>! { get set }

    /// The initial state of the CoordinatorManager. The CoordinatorManager should not require any effort to reach this state.
    var initialState: StateType { get }

    /**
    Determine if the given state transition is valid.

    :param: fromState The state to transition from.
    :param: toState   The state to transition to.

    :returns: true if the state transition is valid; otherwise, false.
    */
    func canTransition(#fromState: StateType, toState: StateType) -> Bool

    /**
    Perform any logic necessary to transition between the given states.

    :param: fromState The current to transition from.
    :param: toState   The new state to transition to.
    */
    func transition(#fromState: StateType, toState: StateType)

}

public protocol CoordinatorImplicitTransitionReversalDelegate: class {
    
    /// If all state transitions are of the form (A <-> B), and never (A -> B) return true in this method.
    var allowImplicitTransitionReversals: Bool { get }
    
}

final public class Coordinator<StateType: Equatable, CM: CoordinatorManager where CM.StateType == StateType>: CoordinatorReference<CM.StateType> {

    private var coordinatorManager: CM!

    /**
    Initialize a Coordinator with the given CoordinatorManager. After being initialized, the CoordinatorManager should not be interacted with directly.

    :param: cm The CoordinatorManager.

    :returns: An initialized Coordinator.
    */
    public init(coordinatorManager cm: CM) {
        coordinatorManager = cm
        super.init(initialState: cm.initialState)
        coordinatorManager.coordinator = self
    }

    /**
    Determine if the Coordinator can transition from its current state to a new state.

    :param: newState The new state you'd like to transition to.

    :returns: true if the Coordinator can transition from its current state to the new state; otherwise, false.
    */
    public override func canTransitionToState(newState: StateType) -> Bool {
        if let previousState = _previousStates.last {
            if newState == previousState {
                if let cm = coordinatorManager as? CoordinatorImplicitTransitionReversalDelegate where cm.allowImplicitTransitionReversals {
                    return true
                }
            }
        }

        return coordinatorManager.canTransition(fromState: currentState, toState: newState)
    }

    /**
    Transition from the current state to the new state. A fatalError will occur if you attempt to transition to an invalid state.

    :param: newState The new state to transition to.
    */
    public override func transitionToState(newState: StateType) {
        transitionToState(newState, forwards: true)
    }

    /**
    Determine if the Coordinator can transition from the current state to its previous state.

    :returns: true if a valid previous state exists and can be transition to; otherwise, false.
    */
    public override func canTransitionBack() -> Bool {
        if let previousState = _previousStates.last {
            return canTransitionToState(previousState)
        } else {
            return false
        }
    }

    /**
    Transition from the current state to the previous state. A fatalError will occur if you attempt to transition to an invalid state.
    */
    public override func transitionBack() {
        if let previousState = _previousStates.last {
            transitionToState(previousState, forwards: false)
        } else {
            fatalError("Illegal state transition, there is no previous state")
        }
    }
    
    /**
    Clear the state stack of previous states.
    */
    public func clearStateStack() {
        _previousStates.removeAll(keepCapacity: false)
    }
    
    public override func unload() {
        coordinatorManager = nil
    }
    
    private func transitionToState(newState: StateType, forwards: Bool) {
        if currentState != newState {
            if canTransitionToState(newState) {
                if forwards {
                    _previousStates.append(currentState)
                } else {
                    _previousStates.removeLast()
                }
                
                let cState = currentState
                currentState = newState
                coordinatorManager.transition(fromState: cState, toState: newState)
            } else {
                fatalError("Illegal state transition: \(currentState) -> \(newState)")
            }
        }
    }

}