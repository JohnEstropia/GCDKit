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
A wrapper and utility class for dispatch_block_t.
*/
@availability(iOS, introduced=8.0)
public struct GCDBlock {
    
    /**
    Submits a closure for asynchronous execution on a queue and returns immediately.
    
    :param: queue The queue to which the supplied block will be submitted.
    :param: closure The closure to submit to the target queue.
    :returns: The block to submit to the queue. Useful when chaining blocks together.
    */
    public static func async(queue: GCDQueue, closure: () -> ()) -> GCDBlock {
        
        return queue.async(closure)
    }
    
    /**
    Submits a closure for execution on a queue and waits until that block completes.
    
    :param: queue The queue to which the supplied block will be submitted.
    :param: closure The closure to submit to the target queue.
    :returns: The block to submit to the queue. Useful when chaining blocks together.
    */
    public static func sync(queue: GCDQueue, closure: () -> ()) -> GCDBlock {
        
        return queue.sync(closure)
    }
    
    /**
    Enqueue a closure for execution at the specified time.
    
    :param: queue The queue to which the supplied block will be submitted.
    :param: delay The number of seconds delay before executing the block
    :param: closure The closure to submit to the target queue.
    :returns: The block to submit to the queue. Useful when chaining blocks together.
    */
    public static func after(queue: GCDQueue, delay: NSTimeInterval, _ closure: () -> ()) -> GCDBlock {
        
        return queue.after(delay, closure)
    }
    
    /**
    Submits a barrier closure for asynchronous execution and returns immediately.
    
    :param: queue The queue to which the supplied block will be submitted.
    :param: closure The closure to submit to the target queue.
    :returns: The block to submit to the queue. Useful when chaining blocks together.
    */
    public static func barrierAsync(queue: GCDQueue, closure: () -> ()) -> GCDBlock {
        
        return queue.barrierAsync(closure)
    }
    
    /**
    Submits a barrier closure object for execution and waits until that block completes.
    
    :param: queue The queue to which the supplied block will be submitted.
    :param: closure The closure to submit to the target queue.
    :returns: The block to submit to the queue. Useful when chaining blocks together.
    */
    public static func barrierSync(queue: GCDQueue, closure: () -> ()) -> GCDBlock {
        
        return queue.barrierSync(closure)
    }
    
    /**
    Synchronously executes the block.
    */
    public func perform() {
        
        self.rawObject()
    }
    
    /**
    Schedule a notification closure to be submitted to a queue when the execution of the block has completed.
    
    :param: queue The queue to which the supplied notification closure will be submitted when the block completes.
    :param: closure The notification closure to submit when the block completes.
    :returns: The notification block. Useful when chaining blocks together.
    */
    public func notify(queue: GCDQueue, closure: () -> ()) -> GCDBlock {
        
        let block = GCDBlock(closure)
        dispatch_block_notify(self.rawObject, queue.dispatchQueue(), block.rawObject)
        
        return block
    }
    
    /**
    Asynchronously cancel the block.
    */
    public func cancel() {
        
        dispatch_block_cancel(self.rawObject)
    }
    
    /**
    Wait synchronously until execution of the block has completed.
    */
    public func wait() {
        
        dispatch_block_wait(self.rawObject, DISPATCH_TIME_FOREVER)
    }
    
    /**
    Wait synchronously until execution of the block has completed or until the specified timeout has elapsed.
    
    :param: timeout The number of seconds before timeout.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(timeout: NSTimeInterval) -> Int {
        
        return dispatch_block_wait(self.rawObject, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Wait synchronously until execution of the block has completed or until the specified timeout has elapsed.
    
    :param: date The timeout date.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(date: NSDate) -> Int {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
    Returns the dispatch_block_t object associated with this value.
    
    :returns: The dispatch_block_t object associated with this value.
    */
    public func dispatchBlock() -> dispatch_block_t {
        
        return self.rawObject
    }
    
    private let rawObject: dispatch_block_t
    
    private init(closure: () -> ()) {
        
        self.rawObject = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            
            autoreleasepool(closure)
            
        }
    }
}

/**
A wrapper and utility class for dispatch_queue_t.
*/
@availability(iOS, introduced=8.0)
public enum GCDQueue {
    
    /**
    The serial queue associated with the application’s main thread
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
    A user-created custom queue. Use DispatchQueue.createSerial() or DispatchQueue.createConcurrent() to create with an associated dispatch_queue_t object.
    */
    case Custom(dispatch_queue_t)
    
    /**
    Creates a custom queue to which blocks can be submitted serially.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :returns: A new custom serial queue.
    */
    public static func createSerial(label: String) -> GCDQueue {
        
        return self.createCustom(isConcurrent: false, label: label, targetQueue: nil)
    }
    
    /**
    Creates a custom queue and specifies a target queue to which blocks can be submitted serially.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :param: targetQueue The new target queue for the custom queue.
    :returns: A new custom serial queue.
    */
    public static func createSerial(label: String, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(isConcurrent: false, label: label, targetQueue: targetQueue)
    }
    
    /**
    Creates a custom queue to which blocks can be submitted concurrently.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :returns: A new custom concurrent queue.
    */
    public static func createConcurrent(label: String) -> GCDQueue {
        
        return self.createCustom(isConcurrent: true, label: label, targetQueue: nil)
    }
    
    /**
    Creates a custom queue and specifies a target queue to which blocks can be submitted concurrently.
    
    :param: label A string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    :param: targetQueue The new target queue for the custom queue.
    :returns: A new custom concurrent queue.
    */
    public static func createConcurrent(label: String, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(isConcurrent: true, label: label, targetQueue: targetQueue)
    }
    
    /**
    Submits a closure for asynchronous execution and returns immediately.
    
    :param: closure The closure to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func async(closure: () -> ()) -> GCDBlock {
        
        return self.async(GCDBlock(closure))
    }
    
    /**
    Submits a block for asynchronous execution and returns immediately.
    
    :param: block The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func async(block: GCDBlock) -> GCDBlock {
        
        dispatch_async(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a closure for execution and waits until that block completes.
    
    :param: closure The closure to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func sync(closure: () -> ()) -> GCDBlock {
        
        return self.sync(GCDBlock(closure))
    }
    
    /**
    Submits a block object for execution on a dispatch queue and waits until that block completes.
    
    :param: block The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func sync(block: GCDBlock) -> GCDBlock {
        
        dispatch_sync(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Enqueue a closure for execution after a specified delay.
    
    :param: delay The number of seconds delay before executing the closure
    :param: closure The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func after(delay: NSTimeInterval, _ closure: () -> ()) -> GCDBlock {
        
        return self.after(delay, GCDBlock(closure))
    }
    
    /**
    Enqueue a block for execution after a specified delay.
    
    :param: delay The number of seconds delay before executing the block
    :param: block The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func after(delay: NSTimeInterval, _ block: GCDBlock) -> GCDBlock {
        
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC))),
            self.dispatchQueue(),
            block.dispatchBlock())
        return block
    }
    
    /**
    Submits a barrier closure for asynchronous execution and returns immediately.
    
    :param: closure The closure to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierAsync(closure: () -> ()) -> GCDBlock {
        
        return self.barrierAsync(GCDBlock(closure))
    }
    
    /**
    Submits a barrier block for asynchronous execution and returns immediately.
    
    :param: closure The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierAsync(block: GCDBlock) -> GCDBlock {
        
        dispatch_barrier_async(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a barrier closure for execution and waits until that block completes.
    
    :param: closure The closure to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierSync(closure: () -> ()) -> GCDBlock {
        
        return self.barrierSync(GCDBlock(closure))
    }
    
    /**
    Submits a barrier block for execution and waits until that block completes.
    
    :param: closure The block to submit.
    :returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierSync(block: GCDBlock) -> GCDBlock {
        
        dispatch_barrier_sync(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a closure for multiple invocations.
    
    :param: iterations The number of iterations to perform.
    :param: closure The closure to submit.
    */
    public func apply(iterations: UInt, _ closure: (iteration: UInt) -> ()) {
        
        dispatch_apply(iterations, self.dispatchQueue()) {
            (iteration: UInt) -> () in
            
            autoreleasepool {
                
                closure(iteration: iteration)
            }
        }
    }
    
    /**
    Returns the dispatch_queue_t object associated with this value.
    
    :returns: The dispatch_queue_t object associated with this value.
    */
    public func dispatchQueue() -> dispatch_queue_t {
        
        switch self {
            
        case .Main:                     return dispatch_get_main_queue()
        case .UserInteractive:          return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
        case .UserInitiated:            return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
        case .Default:                  return dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.value), 0)
        case .Utility:                  return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
        case .Background:               return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
        case .Custom(let rawObject):    return rawObject
        }
    }
    
    private static func createCustom(#isConcurrent: Bool, label: String, targetQueue: GCDQueue?) -> GCDQueue {
        
        let queue = GCDQueue.Custom(dispatch_queue_create(label, (isConcurrent ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL)))
        if let target = targetQueue {
            
            dispatch_set_target_queue(queue.dispatchQueue(), target.dispatchQueue())
        }
        return queue
    }
}

/**
A wrapper and utility class for dispatch_group_t.
*/
@availability(iOS, introduced=8.0)
public struct GCDGroup {
    
    /**
    Creates a new group with which block objects can be associated.
    */
    public init() {
        
        self.rawObject = dispatch_group_create()
    }
    
    /**
    Submits a closure to a queue and associates the closure to the group.
    
    :returns: The group. Useful when chaining async invocations on the group.
    */
    public func async(queue: GCDQueue, _ closure: () -> ()) -> GCDGroup {
        
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
    Schedules a closure to be submitted to a queue when a group of previously submitted blocks have completed.
    
    :param: queue The queue to which the supplied closure is submitted when the group completes.
    :param: closure The closure to submit to the target queue.
    */
    public func notify(queue: GCDQueue, _ closure: () -> ()) {
        
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
    
    :param: timeout The number of seconds before timeout.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(timeout: NSTimeInterval) -> Int {
        
        return dispatch_group_wait(self.rawObject, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Waits synchronously for the previously submitted blocks to complete; returns if the blocks do not complete before the specified date has elapsed.
    
    :param: date The timeout date.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(date: NSDate) -> Int {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
    Returns the dispatch_group_t object associated with this value.
    
    :returns: The dispatch_group_t object associated with this value.
    */
    public func dispatchGroup() -> dispatch_group_t {
        
        return self.rawObject
    }
    
    private let rawObject: dispatch_group_t
}

/**
A wrapper and utility class for dispatch_semaphore_t.
*/
@availability(iOS, introduced=8.0)
public struct GCDSemaphore {
    
    /**
    Creates new counting semaphore with an initial value.
    */
    public init(_ value: Int) {
        
        self.rawObject = dispatch_semaphore_create(value)
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
    
    :returns: This function returns non-zero if a thread is woken. Otherwise, zero is returned.
    */
    public func signal() -> Int {
        
        return dispatch_semaphore_signal(self.rawObject)
    }
    
    /**
    Waits for (decrements) a semaphore.
    */
    public func wait() {
        
        dispatch_semaphore_wait(self.rawObject, DISPATCH_TIME_FOREVER)
    }
    
    /**
    Waits for (decrements) a semaphore.
    
    :param: timeout The number of seconds before timeout.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(timeout: NSTimeInterval) -> Int {
        
        return dispatch_semaphore_wait(self.rawObject, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * NSTimeInterval(NSEC_PER_SEC))))
    }
    
    /**
    Waits for (decrements) a semaphore.
    
    :param: date The timeout date.
    :returns: Returns zero on success, or non-zero if the timeout occurred.
    */
    public func wait(date: NSDate) -> Int {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
    Returns the dispatch_semaphore_t object associated with this value.
    
    :returns: The dispatch_semaphore_t object associated with this value.
    */
    public func dispatchSemaphore() -> dispatch_semaphore_t {
        
        return self.rawObject
    }
    
    private let rawObject: dispatch_semaphore_t
}
