//
//  GCDSemaphore.swift
//  GCDKit
//
//  Copyright © 2014 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/**
A wrapper and utility class for dispatch_semaphore_t.
*/
public struct GCDSemaphore {
    
    /**
    Creates new counting semaphore with an initial value.
    */
    public init(_ value: Int) {
        
        self.rawObject = DispatchSemaphore(value: value)
    }
    
    /**
    Creates new counting semaphore with an initial value.
    */
    public init(_ value: UInt) {
        
        self.init(Int(value))
    }
    
    /**
    Creates new counting semaphore with a zero initial value.
    */
    public init() {
        
        self.init(0)
    }
    
    /**
    Signals (increments) a semaphore.
    
    - returns: This function returns non-zero if a thread is woken. Otherwise, zero is returned.
    */
    public func signal() -> Int {
        
        return self.rawObject.signal()
    }
    
    /**
    Waits for (decrements) a semaphore.
    */
    public func wait() {
        
        self.rawObject.wait()
    }
    
    /**
    Waits for (decrements) a semaphore.
    
     - parameter timeout: The number of seconds before timeout.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
    */
    public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
        
        return self.rawObject.wait(timeout: DispatchTime.now() + timeout)
    }
    
    /**
    Waits for (decrements) a semaphore.
    
     - parameter date: The timeout date.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
    */
    public func wait(_ date: Date) -> DispatchTimeoutResult {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
    Returns the dispatch_semaphore_t object associated with this value.
    
    - returns: The dispatch_semaphore_t object associated with this value.
    */
    public func dispatchSemaphore() -> DispatchSemaphore {
        
        return self.rawObject
    }
    
    fileprivate let rawObject: DispatchSemaphore
}

public func == (lhs: GCDSemaphore, rhs: GCDSemaphore) -> Bool {
    
    return lhs.dispatchSemaphore() === rhs.dispatchSemaphore()
}

extension GCDSemaphore: Equatable { }
