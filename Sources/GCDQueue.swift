//
//  GCDQueue.swift
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

private var _GCDQueue_Specific: Void?

/**
A wrapper and utility class for dispatch_queue_t.
*/
@available(iOS, introduced=7.0)
public enum GCDQueue {
    
    /**
    The serial queue associated with the application’s main thread
    */
    case Main
    
    /**
    A system-defined global concurrent queue with a User Interactive quality of service class. On iOS 7, UserInteractive is equivalent to UserInitiated.
    */
    case UserInteractive
    
    /**
    A system-defined global concurrent queue with a User Initiated quality of service class. On iOS 7, UserInteractive is equivalent to UserInitiated.
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
    
    - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    - returns: A new custom serial queue.
    */
    public static func createSerial(label: String? = nil) -> GCDQueue {
        
        return self.createCustom(isConcurrent: false, label: label, targetQueue: nil)
    }
    
    /**
    Creates a custom queue and specifies a target queue to which blocks can be submitted serially.
    
    - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    - parameter targetQueue: The new target queue for the custom queue.
    - returns: A new custom serial queue.
    */
    public static func createSerial(label: String? = nil, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(isConcurrent: false, label: label, targetQueue: targetQueue)
    }
    
    /**
    Creates a custom queue to which blocks can be submitted concurrently.
    
    - parameter label: A String label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    - returns: A new custom concurrent queue.
    */
    public static func createConcurrent(label: String? = nil) -> GCDQueue {
        
        return self.createCustom(isConcurrent: true, label: label, targetQueue: nil)
    }
    
    /**
    Creates a custom queue and specifies a target queue to which blocks can be submitted concurrently.
    
    - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
    - parameter targetQueue: The new target queue for the custom queue.
    - returns: A new custom concurrent queue.
    */
    public static func createConcurrent(label: String? = nil, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(isConcurrent: true, label: label, targetQueue: targetQueue)
    }
    
    /**
    Submits a closure for asynchronous execution and returns immediately.
    
    - parameter closure: The closure to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func async(closure: () -> Void) -> GCDBlock {
        
        return self.async(GCDBlock(closure))
    }
    
    /**
    Submits a block for asynchronous execution and returns immediately.
    
    - parameter block: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func async(block: GCDBlock) -> GCDBlock {
        
        dispatch_async(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a closure for execution and waits until that block completes.
    
    - parameter closure: The closure to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func sync(closure: () -> Void) -> GCDBlock {
        
        return self.sync(GCDBlock(closure))
    }
    
    /**
    Submits a block object for execution on a dispatch queue and waits until that block completes.
    
    - parameter block: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func sync(block: GCDBlock) -> GCDBlock {
        
        dispatch_sync(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Enqueue a closure for execution after a specified delay.
    
    - parameter delay: The number of seconds delay before executing the closure
    - parameter closure: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func after(delay: NSTimeInterval, _ closure: () -> Void) -> GCDBlock {
        
        return self.after(delay, GCDBlock(closure))
    }
    
    /**
    Enqueue a block for execution after a specified delay.
    
    - parameter delay: The number of seconds delay before executing the block
    - parameter block: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
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
    
    - parameter closure: The closure to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierAsync(closure: () -> Void) -> GCDBlock {
        
        return self.barrierAsync(GCDBlock(closure))
    }
    
    /**
    Submits a barrier block for asynchronous execution and returns immediately.
    
    - parameter closure: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierAsync(block: GCDBlock) -> GCDBlock {
        
        dispatch_barrier_async(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a barrier closure for execution and waits until that block completes.
    
    - parameter closure: The closure to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierSync(closure: () -> Void) -> GCDBlock {
        
        return self.barrierSync(GCDBlock(closure))
    }
    
    /**
    Submits a barrier block for execution and waits until that block completes.
    
    - parameter closure: The block to submit.
    - returns: The block to submit. Useful when chaining blocks together.
    */
    public func barrierSync(block: GCDBlock) -> GCDBlock {
        
        dispatch_barrier_sync(self.dispatchQueue(), block.dispatchBlock())
        return block
    }
    
    /**
    Submits a closure for multiple invocations.
    
    - parameter iterations: The number of iterations to perform.
    - parameter closure: The closure to submit.
    */
    public func apply<T: UnsignedIntegerType>(iterations: T, _ closure: (iteration: T) -> Void) {
        
        dispatch_apply(numericCast(iterations), self.dispatchQueue()) { (iteration) -> Void in
            
            autoreleasepool {
                
                closure(iteration: numericCast(iteration))
            }
        }
    }
    
    /**
    Checks if the queue is the current execution context. Global queues other than the main queue are not supported and will always return nil.
    
    - returns: true if the queue is the current execution context, or false if it is not.
    */
    public func isCurrentExecutionContext() -> Bool {
        
        let dispatchQueue = self.dispatchQueue()
        let rawPointer = UnsafeMutablePointer<Void>(bitPattern: ObjectIdentifier(dispatchQueue).uintValue)
        
        dispatch_queue_set_specific(
            dispatchQueue,
            &_GCDQueue_Specific,
            rawPointer,
            nil)
        
        return dispatch_get_specific(&_GCDQueue_Specific) == rawPointer
    }
    
    /**
    Returns the dispatch_queue_t object associated with this value.
    
    - returns: The dispatch_queue_t object associated with this value.
    */
    public func dispatchQueue() -> dispatch_queue_t {
        
        #if USE_FRAMEWORKS
            
            switch self {
                
            case .Main:
                return dispatch_get_main_queue()
                
            case .UserInteractive:
                return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
                
            case .UserInitiated:
                return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                
            case .Default:
                return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
                
            case .Utility:
                return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
                
            case .Background:
                return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
                
            case .Custom(let rawObject):
                return rawObject
            }
        #else
            
            switch self {
                
            case .Main:
                return dispatch_get_main_queue()
                
            case .UserInteractive:
                if #available(iOS 8.0, *) {
                    
                    return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
                }
                else {
                    
                    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
                }
                
            case .UserInitiated:
                if #available(iOS 8.0, *) {
                    
                    return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                }
                else {
                    
                    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
                }
                
            case .Default:
                if #available(iOS 8.0, *) {
                    
                    return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
                }
                else {
                    
                    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                }
                
            case .Utility:
                if #available(iOS 8.0, *) {
                    
                    return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
                }
                else {
                    
                    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                }
                
            case .Background:
                if #available(iOS 8.0, *) {
                    
                    return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
                }
                else {
                    
                    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
                }
                
            case .Custom(let rawObject):
                return rawObject
            }
        #endif
    }
    
    private static func createCustom(isConcurrent isConcurrent: Bool, label: String?, targetQueue: GCDQueue?) -> GCDQueue {
        
        let queue = GCDQueue.Custom(
            dispatch_queue_create(
                label.flatMap { ($0 as NSString).UTF8String } ?? nil,
                (isConcurrent ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL)
            )
        )
        
        if let target = targetQueue {
            
            dispatch_set_target_queue(queue.dispatchQueue(), target.dispatchQueue())
        }
        return queue
    }
}

public func ==(lhs: GCDQueue, rhs: GCDQueue) -> Bool {
    
    switch (lhs, rhs) {
        
    case (.Main, .Main):
        return true
        
    case (.UserInteractive, .UserInteractive):
        return true
        
    case (.UserInitiated, .UserInitiated):
        return true
        
    case (.Default, .Default):
        return true
        
    case (.Utility, .Utility):
        return true
        
    case (.Background, .Background):
        return true
        
    case (.Custom(let lhsRawObject), .Custom(let rhsRawObject)):
        return lhsRawObject === rhsRawObject

    case (.UserInitiated, .UserInteractive), (.UserInteractive, .UserInitiated):
        #if USE_FRAMEWORKS
            
            return false
        #else
            
            if #available(iOS 8.0, *) {
                
                return false
            }
            return true
        #endif
        
    default:
        return false
    }
}

extension GCDQueue: Equatable { }
