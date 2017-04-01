//
//  GCDGroup.swift
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
 A wrapper and utility class for dispatch_group_t.
 */
public struct GCDGroup {
    
    /**
     Creates a new group with which block objects can be associated.
     */
    public init() {
        
        self.rawObject = DispatchGroup()
    }
    
    /**
     Submits a closure to a queue and associates the closure to the group.
     
     - returns: The group. Useful when chaining async invocations on the group.
     */
    @discardableResult
    public func async(_ queue: GCDQueue, _ closure: @escaping () -> Void) -> GCDGroup {
        
        queue.dispatchQueue().async(group: self.rawObject, execute: closure)
        return self
    }
    
    /**
     Explicitly indicates that a block has entered the group.
     */
    public func enter() {
        
        self.rawObject.enter()
    }
    
    /**
     Explicitly indicates that a block in the group has completed.
     */
    public func leave() {
        
        self.rawObject.leave()
    }
    
    /**
     Explicitly indicates that a block has entered the group.
     - returns: Returns a once-token that may be passed to `leaveOnce()`
     */
    public func enterOnce() -> Int32 {
        
        self.rawObject.enter()
        return 1
    }
    
    /**
     Explicitly indicates that a block in the group has completed. This method accepts a `onceToken` which `GCDGroup` can used to prevent multiple calls `dispatch_group_leave()` which may crash the app.
     
     - parameter onceToken: The address of the value returned from `enterOnce()`.
     - returns: Returns `true` if `dispatch_group_leave()` was called, or `false` if not.
     */
    @discardableResult
    public func leaveOnce(_ onceToken: inout Int32) -> Bool {
        
        if OSAtomicCompareAndSwapInt(1, 0, &onceToken) {
            
            self.rawObject.leave()
            return true
        }
        return false
    }
    
    /**
     Schedules a closure to be submitted to a queue when a group of previously submitted blocks have completed.
     
     - parameter queue: The queue to which the supplied closure is submitted when the group completes.
     - parameter closure: The closure to submit to the target queue.
     */
    public func notify(_ queue: GCDQueue, _ closure: @escaping () -> Void) {
        
        self.rawObject.notify(queue: queue.dispatchQueue(), execute: closure)
    }
    
    /**
     Waits synchronously for the previously submitted blocks to complete.
     */
    public func wait() {
        
        _ = self.rawObject.wait(timeout: DispatchTime.distantFuture)
    }
    
    /**
     Waits synchronously for the previously submitted blocks to complete; returns if the blocks do not complete before the specified timeout period has elapsed.
     
     - parameter timeout: The number of seconds before timeout.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
     */
    public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
        
        return self.rawObject.wait(timeout: DispatchTime.now() + timeout)
    }
    
    /**
     Waits synchronously for the previously submitted blocks to complete; returns if the blocks do not complete before the specified date has elapsed.
     
     - parameter date: The timeout date.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
     */
    public func wait(_ date: Date) -> DispatchTimeoutResult {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
     Returns the dispatch_group_t object associated with this value.
     
     - returns: The dispatch_group_t object associated with this value.
     */
    public func dispatchGroup() -> DispatchGroup {
        
        return self.rawObject
    }
    
    fileprivate let rawObject: DispatchGroup
}

public func == (lhs: GCDGroup, rhs: GCDGroup) -> Bool {
    
    return lhs.dispatchGroup() === rhs.dispatchGroup()
}

extension GCDGroup: Equatable { }
