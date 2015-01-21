//
//  GCDQueue.swift
//  GCDKit
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

private var _GCDQueue_Specific: Void?

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
    public func async(closure: GCDClosure) -> GCDBlock {
        
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
    public func sync(closure: GCDClosure) -> GCDBlock {
        
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
    public func after(delay: NSTimeInterval, _ closure: GCDClosure) -> GCDBlock {
        
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
    public func barrierAsync(closure: GCDClosure) -> GCDBlock {
        
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
    public func barrierSync(closure: GCDClosure) -> GCDBlock {
        
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
    Suspends the invocation of blocks on this queue. Note that suspending and resuming is only allowed for custom serial/concurrent queues.
    */
    public func suspend() {
        
        switch self {
            
        case .Custom(let rawObject):
            dispatch_suspend(rawObject)
            
        default:
            assertionFailure("Global queues cannot be suspended or resumed.")
        }
    }
    
    /**
    Resume the invocation of blocks on this queue. Note that suspending and resuming is only allowed for custom serial/concurrent queues.
    */
    public func resume() {
        
        switch self {
            
        case .Custom(let rawObject):
            dispatch_resume(rawObject)
            
        default:
            assertionFailure("Global queues cannot be suspended or resumed.")
        }
    }
    
    /**
    Checks if the queue is the current execution context. Global queues other than the main queue are not supported and will always return nil.
    
    :returns: true if the queue is the current execution context, or false if it is not. Global queues other than the main queue are not supported and will always return nil.
    */
    public func isCurrentExecutionContext() -> Bool? {
        
        switch self {
            
        case .Main:
            return NSThread.isMainThread()
        case .Custom(let rawObject):
            return dispatch_queue_get_specific(rawObject, &_GCDQueue_Specific)
                == unsafeBitCast(rawObject, UnsafeMutablePointer<Void>.self)
        default: return nil
        }
    }
    
    /**
    Returns the dispatch_queue_t object associated with this value.
    
    :returns: The dispatch_queue_t object associated with this value.
    */
    public func dispatchQueue() -> dispatch_queue_t {
        
        switch self {
            
        case .Main:
            return dispatch_get_main_queue()
        case .UserInteractive:
            return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
        case .UserInitiated:
            return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
        case .Default:
            return dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.value), 0)
        case .Utility:
            return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
        case .Background:
            return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
        case .Custom(let rawObject):
            return rawObject
        }
    }
    
    private static func createCustom(#isConcurrent: Bool, label: String, targetQueue: GCDQueue?) -> GCDQueue {
        
        let queue = GCDQueue.Custom(dispatch_queue_create(label, (isConcurrent ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL)))
        
        let rawObject = queue.dispatchQueue()
        dispatch_queue_set_specific(
            rawObject,
            &_GCDQueue_Specific,
            unsafeBitCast(rawObject, UnsafeMutablePointer<Void>.self),
            nil)
        
        if let target = targetQueue {
            
            dispatch_set_target_queue(rawObject, target.dispatchQueue())
        }
        return queue
    }
}
