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

/**
    An enum representing the current state of the Promise or Future.

    - Incomplete: The Promise or Future is still running.
    - Complete: The Promise or Future has received a value.
    - Invalid: The Promise or Future has received an error.
*/
public enum DerefState {
    case Incomplete
    case Complete
    case Invalid
}

private enum LockState: Int {
    case Waiting
    case Complete
}

/**
    This Box class is a workaround for an unsupported feature in Swift. Hopefully someday this can go away.
*/
public class Box<T> {
    public let unbox: T
    public init(_ value: T) { unbox = value }
}

public enum DerefValue<T> {
    case Success(Box<T>)
    case Error(NSError)

    public var successValue: T? {
        get {
            switch self {
            case .Success(let box):
                return box.unbox
            default:
                return nil
            }
        }
    }

    public var error: NSError? {
        get {
            switch self {
            case .Error(let error):
                return error
            default:
                return nil
            }
        }
    }
}

public class Deref<T> {

    public typealias DerefSuccessHandler = (value: T) -> ()
    public typealias DerefErrorHandler = (error: NSError) -> ()

    /// Specify the queue on which to call the completion handler. The default value is the main queue.
    lazy public var completionQueue = dispatch_get_main_queue()

    /// Returns the delivered value, potentially blocking indefinitely until a value is delivered or the Promise or Future is invalidated.
    public var value: DerefValue<T> {
        get {
            if lock.condition != LockState.Complete.rawValue {
                lock.lockWhenCondition(LockState.Complete.rawValue)
                lock.unlock()
            }

            return valueStorage!
        }
    }

    /// Returns the Promise or Future's successValue, or nil.
    public var successValue: T? {
        get {
            return value.successValue
        }
    }

    /// Returns the Promise or Future's error, or nil.
    public var error: NSError? {
        get {
            return value.error
        }
    }

    /// The current state of the Promise or Future.
    public var state: DerefState {
        get {
            var s = DerefState.Incomplete
            OSSpinLockLock(&spinLock)
            s = stateStorage
            OSSpinLockUnlock(&spinLock)
            return s
        }
    }

    /// false if the Promise or Future has been invalidated; otherwise, true.
    public var valid: Bool {
        get {
            return state != .Invalid
        }
    }

    private var lock = NSConditionLock(condition: LockState.Waiting.rawValue)
    private var spinLock = OS_SPINLOCK_INIT
    private var valueStorage: DerefValue<T>?
    private var successHandler: DerefSuccessHandler?
    private var errorHandler: DerefErrorHandler?
    private var stateStorage = DerefState.Incomplete

    /* You may not publicly initialize a Deref. */
    internal init() {}

    /**
    Returns the value that was delivered to the Promise or Future or nil if a value is not delivered within the specified timeout.

    :param: timeout The maximum amount of time to wait for a value to be delivered.

    :returns: The value that was delivered to the Promise or Future or nil if a value or error is not delivered within the specified timeout.
    */
    public func valueWithTimeout(timeout: NSTimeInterval) -> DerefValue<T>? {
        if lock.condition != LockState.Complete.rawValue {
            if self.lock.lockWhenCondition(LockState.Complete.rawValue, beforeDate: NSDate(timeIntervalSinceNow: timeout)) {
                self.lock.unlock()
            }
        }

        return valueStorage
    }

    /**
    Attaches a success handler to the Promise or Future.

    :param: handler The success handler.

    :returns: The receiver to allow for further chaining.
    */
    public func onSuccess(handler: (value: T) -> ()) -> Self {
        successHandler = handler
        return self
    }

    /**
    Attaches an error handler to the Promise or Future.

    :param: handler The error handler.

    :returns: The receiver to allow for further chaining.
    */
    public func onError(handler: (error: NSError) -> ()) -> Self {
        errorHandler = handler
        return self
    }

    internal func deliver(value: DerefValue<T>) -> Bool {
        var success = false

        if lock.tryLockWhenCondition(LockState.Waiting.rawValue) {
            OSSpinLockLock(&spinLock)
            success = true
            valueStorage = value

            if value.successValue == nil {
                stateStorage = .Invalid
            } else {
                stateStorage = .Complete
            }

            OSSpinLockUnlock(&spinLock)
            lock.unlockWithCondition(LockState.Complete.rawValue)

            switch value {
            case .Success(let box):
                if let sh = self.successHandler {
                    dispatch_async(self.completionQueue) {
                        sh(value: box.unbox)
                    }
                }
            case .Error(let error):
                if let eh = self.errorHandler {
                    dispatch_async(self.completionQueue) {
                        eh(error: error)
                    }
                }
            }

        }

        return success
    }

}
