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

public class FutureCache<T> {

    private var cache = [String: Future<T>]()
    lazy private var futureCacheQueue = dispatch_queue_create("FutureCacheQueue", DISPATCH_QUEUE_SERIAL)

    public init() {}

    /**
    Adds a Future to the cache.

    :param: key    The key to store the Future by.
    :param: future The Future to store.
    */
    public func add(key: String, future: Future<T>) {
        dispatch_async(futureCacheQueue) {
            self.cache[key] = future
        }
    }

    /**
    Cancels and removes a Future from the cache.

    :param: key The key to remove.
    */
    public func remove(key: String) {
        if let future = futureForKey(key) {
            future.cancel()

            dispatch_async(futureCacheQueue) {
                self.cache.removeValueForKey(key)
            }
        }
    }

    /**
    Cancels all Futures in the cache and then empties the cache.
    */
    public func cancelAndRemoveAll() {
        dispatch_sync(futureCacheQueue) {
            for (_, future) in self.cache {
                future.cancel()
            }

            self.cache.removeAll(keepCapacity: false)
        }
    }

    /**
    Returns the Future's value, or nil if the future didn't exist.

    :param: key The key.

    :returns: The Future's value, or nil if the future didn't exist.
    */
    public func resultForKey(key: String) -> DerefValue<T>? {
        return futureForKey(key)?.value
    }

    /**
    Returns the Future's .Success value or the provided defaultValue if the Future was invalid or did not exist in the cache.

    :param: key          The key.
    :param: defaultValue The default value to use if the Future was invalid or did not exist in the cache.

    :returns: The Future's .Success value or the provided defaultValue if the Future was invalid or did not exist in the cache.
    */
    public func valueForKey(key: String, @autoclosure defaultValue: () -> (T)) -> T {
        if let result = resultForKey(key), value = result.successValue {
            return value
        }

        return defaultValue()
    }

    /**
    Returns the Future's value, or nil if it is invalid or did not exist in the cache.

    :param: key The key.

    :returns: The Future's value, or nil if it is invalid or did not exist in the cache.
    */
    public func valueForKey(key: String) -> T? {
        return resultForKey(key)?.successValue
    }

    /**
    Returns the Future for the given key.

    :param: key The key.

    :returns: The future, or nil, for the given key.
    */
    public func futureForKey(key: String) -> Future<T>? {
        var f: Future<T>?
        dispatch_sync(futureCacheQueue) {
            f = self.cache[key]
        }
        return f
    }

}
