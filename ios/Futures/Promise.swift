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

final public class Promise<T>: Deref<T> {

    public override init() {}

    /**
    Delivers a value to the Promise.

    :param: value The value to deliver.

    :returns: true if the value was delivered successfully; otherwise, false if a value has already been delivered or invalidated.
    */
    public func deliver(value: T) -> Bool {
        return deliver(.Success(Box(value)))
    }

    /**
    Invalidates the Promise with the given error. Fails if the Promise was previously delivered, or invalidated.

    :param: error The error to invalidate the Promise with.

    :returns: true if the Promise was invalidated successfully; otherwise, false if it was previously delivered or invalidated.
    */
    public func invalidate(error: NSError) -> Bool {
        return deliver(.Error(error))
    }

}
