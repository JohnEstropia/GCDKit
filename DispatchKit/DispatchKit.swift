//
//  DispatchKit.swift
//  DispatchKit
//
//  Copyright (c) 2014 John Rommel Estropia
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
A dispatch queue is a lightweight object to which your application submits blocks for subsequent execution.
*/
public enum GCDQueue {
    
    /**
    The serial dispatch queue associated with the application’s main thread
    */
    case Main
    
    /**
    A system-defined global concurrent queue with a User Interactive quality of service class.
    */
    case UserInteractive
    
    /**
    A system-defined global concurrent queue with a User Initiated quality of service class.
    */
    case UserInitiated
    
    /**
    A system-defined global concurrent queue with a Default quality of service class.
    */
    case Default
    
    /**
    A system-defined global concurrent queue with a Utility quality of service class.
    */
    case Utility
    
    /**
    A system-defined global concurrent queue with a Background quality of service class.
    */
    case Background
    
    /**
    A user-created custom queue. Use DispatchQueue.createSerial() or DispatchQueue.createConcurrent() to create the associated dispatch_queue_t object.
    */
    case Custom(dispatch_queue_t)
    
    /**
    Returns the dispatch_queue_t object associated with this value.
    
    :returns: The dispatch_queue_t object associated with this value.
    */
    public func dispatchObject() -> dispatch_queue_t {
        
        switch self {
            
        case .Main:                         return dispatch_get_main_queue()
        case .UserInteractive:              return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
        case .UserInitiated:                return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
        case .Default:                      return dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.value), 0)
        case .Utility:                      return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
        case .Background:                   return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
        case .Custom(let dispatchQueue):    return dispatchQueue
        }
    }
    
    /**
    Creates a DispatchQueue.Custom to which blocks can be submitted serially.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :returns: A new serial DispatchQueue.Custom.
    */
    public static func createSerial(label: String = "") -> GCDQueue {
        
        return .Custom(dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL))
    }
    
    /**
    Creates a DispatchQueue.Custom to which blocks can be submitted concurrently.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :returns: A new concurrent DispatchQueue.Custom.
    */
    public static func createConcurrent(label: String = "") -> GCDQueue {
        
        return .Custom(dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT))
    }
    
    /**
    Submits a block for asynchronous execution on a dispatch queue and returns immediately.
    
    :param: closure The block to submit to the target dispatch queue.
    */
    public func async(closure: (Void) -> Void) {
        
        dispatch_async(self.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Enqueue a block for execution at the specified time.
    
    :param: delay The number of seconds delay before executing the block
    :param: closure The block to submit to the target dispatch queue.
    */
    public func after(delay: NSTimeInterval, _ closure: (Void) -> Void) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC))), self.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Submits a block to a dispatch queue for multiple invocations.
    
    :param: iterations The number of iterations to perform.
    :param: closure The block to submit to the target dispatch queue.
    */
    public func apply(iterations: UInt, _ closure: (iteration: UInt) -> Void) {
        
        dispatch_apply(iterations, self.dispatchObject()) { (iteration: UInt) -> Void in
            
            autoreleasepool {
                
                closure(iteration: iteration)
            }
        }
    }
    
    /**
    Submits a barrier block for asynchronous execution and returns immediately.
    
    :param: closure The block to submit to the target dispatch queue.
    */
    public func barrierAsync(closure: (Void) -> Void) {
        
        dispatch_barrier_async(self.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Submits a barrier block object for execution and waits until that block completes.
    
    :param: closure The block to submit to the target dispatch queue.
    */
    public func barrierSync(closure: (Void) -> Void) {
        
        dispatch_barrier_sync(self.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
}

/**
A group of block objects submitted to a queue for asynchronous invocation.
*/
public struct GCDGroup {
    
    /**
    Creates a new group with which block objects can be associated.
    */
    public init() {
        
        self.dispatchGroup = dispatch_group_create()
    }
    
    /**
    Returns the dispatch_group_t object associated with this value.
    
    :returns: The dispatch_group_t object associated with this value.
    */
    public func dispatchObject() -> dispatch_group_t {
        
        return self.dispatchGroup
    }
    
    /**
    Submits a block to a dispatch queue and associates the block with the specified dispatch group.
    */
    public func async(queue: GCDQueue, _ closure: (Void) -> Void) {
        
        dispatch_group_async(self.dispatchGroup, queue.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Explicitly indicates that a block has entered the group.
    */
    public func enter() {
        
        dispatch_group_enter(self.dispatchGroup)
    }
    
    /**
    Explicitly indicates that a block in the group has completed.
    */
    public func leave() {
        
        dispatch_group_leave(self.dispatchGroup)
    }
    
    /**
    Schedules a block object to be submitted to a queue when a group of previously submitted block objects have completed.
    
    :param: queue The queue to which the supplied block is submitted when the group completes.
    :param: closure The block to submit to the target dispatch queue.
    */
    public func notify(queue: GCDQueue, _ closure: (Void) -> Void) {
        
        dispatch_group_notify(self.dispatchGroup, queue.dispatchObject()) {
            
            autoreleasepool(closure)
        }
    }
    
    /**
    Waits synchronously for the previously submitted block objects to complete.
    */
    public func wait() {
        
        dispatch_group_wait(self.dispatchGroup, DISPATCH_TIME_FOREVER)
    }
    
    /**
    Waits synchronously for the previously submitted block objects to complete; returns if the blocks do not complete before the specified timeout period has elapsed.
    
    :param: timeout The number of seconds before timeout.
    */
    public func wait(timeout: NSTimeInterval) {
        
        dispatch_group_wait(self.dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Waits synchronously for the previously submitted block objects to complete; returns if the blocks do not complete before the specified date has elapsed.
    
    :param: date The timeout date.
    */
    public func wait(date: NSDate) {
        
        self.wait(date.timeIntervalSinceNow)
    }
    
    private let dispatchGroup: dispatch_group_t
}

/**
A counting semaphore.
*/
public struct GCDSemaphore {
    
    /**
    Creates new counting semaphore with an initial value.
    */
    public init(_ value: Int) {
        
        self.dispatchSemaphore = dispatch_semaphore_create(value)
    }
    
    /**
    Creates new counting semaphore with a zero initial value.
    */
    public init() {
        
        self.init(0)
    }
    
    /**
    Returns the dispatch_semaphore_t object associated with this value.
    
    :returns: The dispatch_semaphore_t object associated with this value.
    */
    public func dispatchObject() -> dispatch_semaphore_t {
        
        return self.dispatchSemaphore
    }
    
    /**
    Signals (increments) a semaphore.
    
    :returns: This function returns non-zero if a thread is woken. Otherwise, zero is returned.
    */
    public func signal() -> Int {
        
        return dispatch_semaphore_signal(self.dispatchSemaphore)
    }
    
    /**
    Waits for (decrements) a semaphore.
    
    :returns: Returns zero on success.
    */
    public func wait() -> Int {
        
        return dispatch_semaphore_wait(self.dispatchSemaphore, DISPATCH_TIME_FOREVER)
    }
    
    /**
    Waits for (decrements) a semaphore.
    
    :param: timeout The number of seconds before timeout.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(timeout: NSTimeInterval) -> Int {
        
        return dispatch_semaphore_wait(self.dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Waits for (decrements) a semaphore.
    
    :param: date The timeout date.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(date: NSDate) -> Int {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    private let dispatchSemaphore: dispatch_semaphore_t
}
