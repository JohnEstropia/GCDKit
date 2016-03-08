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
@available(iOS, introduced=7.0)
public struct GCDGroup {
    
    /**
    Creates a new group with which block objects can be associated.
    */
    public init() {
        
        self.rawObject = dispatch_group_create()
    }
    
    /**
    Submits a closure to a queue and associates the closure to the group.
    
    - returns: The group. Useful when chaining async invocations on the group.
    */
    public func async(queue: GCDQueue, _ closure: () -> Void) -> GCDGroup {
        
        dispatch_group_async(self.rawObject, queue.dispatchQueue()) {
            
            autoreleasepool(closure)
        }
        return self
    }
    
    /**
    Explicitly indicates that a block has entered the group.
    */
    public func enter() {
        
        dispatch_group_enter(self.rawObject)
    }
    
    /**
    Explicitly indicates that a block in the group has completed.
    */
    public func leave() {
        
        dispatch_group_leave(self.rawObject)
    }
    
    /**
    Explicitly indicates that a block has entered the group.
    - returns: Returns a once-token that may be passed to `leaveOnce()`
    */
    public func enterOnce() -> Int32 {
        
        dispatch_group_enter(self.rawObject)
        return 1
    }
    
    /**
    Explicitly indicates that a block in the group has completed. This method accepts a `onceToken` which `GCDGroup` can used to prevent multiple calls `dispatch_group_leave()` which may crash the app.

    - parameter onceToken: The address of the value returned from `enterOnce()`.
    - returns: Returns `true` if `dispatch_group_leave()` was called, or `false` if not.
    */
    public func leaveOnce(inout onceToken: Int32) -> Bool {
        
        if OSAtomicCompareAndSwapInt(1, 0, &onceToken) {
            
            dispatch_group_leave(self.rawObject)
            return true
        }
        return false
    }
    
    /**
    Schedules a closure to be submitted to a queue when a group of previously submitted blocks have completed.
    
    - parameter queue: The queue to which the supplied closure is submitted when the group completes.
    - parameter closure: The closure to submit to the target queue.
    */
    public func notify(queue: GCDQueue, _ closure: () -> Void) {
        
        dispatch_group_notify(self.rawObject, queue.dispatchQueue()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Waits synchronously for the previously submitted blocks to complete.
    */
    public func wait() {
        
        dispatch_group_wait(self.rawObject, DISPATCH_TIME_FOREVER)
    }
    
    /**
    Waits synchronously for the previously submitted blocks to complete; returns if the blocks do not complete before the specified timeout period has elapsed.
    
    - parameter timeout: The number of seconds before timeout.
    - returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(timeout: NSTimeInterval) -> Int {
        
        return dispatch_group_wait(self.rawObject, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Waits synchronously for the previously submitted blocks to complete; returns if the blocks do not complete before the specified date has elapsed.
    
    - parameter date: The timeout date.
    - returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(date: NSDate) -> Int {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
    Returns the dispatch_group_t object associated with this value.
    
    - returns: The dispatch_group_t object associated with this value.
    */
    public func dispatchGroup() -> dispatch_group_t {
        
        return self.rawObject
    }
    
    private let rawObject: dispatch_group_t
}

public func ==(lhs: GCDGroup, rhs: GCDGroup) -> Bool {
    
    return lhs.dispatchGroup() === rhs.dispatchGroup()
}

extension GCDGroup: Equatable { }
