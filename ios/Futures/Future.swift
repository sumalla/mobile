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

private let globalFutureQueue = dispatch_queue_create("FutureQueue", DISPATCH_QUEUE_CONCURRENT)

public let FutureErrorDomain = "com.SMD.Future.FutureErrorDomain"

public enum FutureError: Int {
    case Canceled
}

/* Shorthand for a Future that is known to only succeed and doesn't care about cancelation. */
public func future<T>(work: () -> T) -> Future<T> {
    return Future<T>() { _ in
        .Success(Box(work()))
    }
}

/* Shorthand for a Future that is known to only succeed and doesn't care about cancelation. */
public func future<T>(@autoclosure(escaping) work: () -> T) -> Future<T> {
    return Future<T>() { _ in
        .Success(Box(work()))
    }
}

final public class Future<T>: Deref<T> {

    /**
    Initializes a Future with the given work and queue.

    :param: queue The queue on which to perform the given work.
    :param: work  The work to perform.

    :returns: An initialized Future.
    */
    public init(queue: dispatch_queue_t, work: (isCanceled: () -> Bool) -> DerefValue<T>) {
        super.init()
        dispatch_async(queue) {
            self.deliver(work() {
                return !self.valid
            })
        }
    }

    /**
    Initializes a Future with the given work. The work will be performed on a default concurrent background queue.

    :param: work The work to perform.

    :returns: An initialized Future.
    */
    public convenience init(work: (isCanceled: () -> Bool) -> DerefValue<T>) {
        self.init(queue: globalFutureQueue, work: work)
    }

    /**
    Cancel the receiver with the FutureErrorDomain and FutureError.Canceled code.

    :returns: true if the Future could be caneled; otherwise, false if the future was already canceled or complete.
    */
    public func cancel() -> Bool {
        return self.deliver(.Error(NSError(domain: FutureErrorDomain, code: FutureError.Canceled.rawValue, userInfo: nil)))
    }

}

public extension dispatch_queue_t {

    /* Shorthand for creating a Future and associating it with a queue. */
    public func createFuture<T>(work: (isCanceled: () -> Bool) -> DerefValue<T>) -> Future<T> {
        return Future<T>(queue: self, work: work)
    }

    /* Shorthand for creating a Future that is known to only succeed and associating it with a queue. */
    public func createFuture<T>(work: () -> T) -> Future<T> {
        return Future<T>(queue: self) { _ in
            .Success(Box(work()))
        }
    }

    /* Shorthand for creating a Future that is known to only succeed and associating it with a queue. */
    public func createFuture<T>(@autoclosure(escaping) work: () -> T) -> Future<T> {
        return Future<T>(queue: self) { _ in
            .Success(Box(work()))
        }
    }

}
