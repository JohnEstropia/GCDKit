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

private let _GCDQueue_Specific = DispatchSpecificKey<ObjectIdentifier>()

/**
 A wrapper and utility class for dispatch_queue_t.
 */
public enum GCDQueue {
    
    /**
     The serial queue associated with the application’s main thread
     */
    case main
    
    /**
     A system-defined global concurrent queue with a User Interactive quality of service class. On iOS 7, UserInteractive is equivalent to UserInitiated.
     */
    case userInteractive
    
    /**
     A system-defined global concurrent queue with a User Initiated quality of service class. On iOS 7, UserInteractive is equivalent to UserInitiated.
     */
    case userInitiated
    
    /**
     A system-defined global concurrent queue with a Default quality of service class.
     */
    case `default`
    
    /**
     A system-defined global concurrent queue with a Utility quality of service class.
     */
    case utility
    
    /**
     A system-defined global concurrent queue with a Background quality of service class.
     */
    case background
    
    /**
     A user-created custom queue. Use DispatchQueue.createSerial() or DispatchQueue.createConcurrent() to create with an associated dispatch_queue_t object.
     */
    case custom(DispatchQueue)
    
    /**
     Creates a custom queue to which blocks can be submitted serially.
     
     - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
     - returns: A new custom serial queue.
     */
    public static func createSerial(_ label: String? = nil) -> GCDQueue {
        
        return self.createCustom(false, label: label, targetQueue: nil)
    }
    
    /**
     Creates a custom queue and specifies a target queue to which blocks can be submitted serially.
     
     - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
     - parameter targetQueue: The new target queue for the custom queue.
     - returns: A new custom serial queue.
     */
    public static func createSerial(_ label: String? = nil, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(false, label: label, targetQueue: targetQueue)
    }
    
    /**
     Creates a custom queue to which blocks can be submitted concurrently.
     
     - parameter label: A String label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
     - returns: A new custom concurrent queue.
     */
    public static func createConcurrent(_ label: String? = nil) -> GCDQueue {
        
        return self.createCustom(true, label: label, targetQueue: nil)
    }
    
    /**
     Creates a custom queue and specifies a target queue to which blocks can be submitted concurrently.
     
     - parameter label: An optional string label to attach to the queue to uniquely identify it in debugging tools such as Instruments, sample, stackshots, and crash reports.
     - parameter targetQueue: The new target queue for the custom queue.
     - returns: A new custom concurrent queue.
     */
    public static func createConcurrent(_ label: String? = nil, targetQueue: GCDQueue) -> GCDQueue {
        
        return self.createCustom(true, label: label, targetQueue: targetQueue)
    }
    
    /**
     Submits a closure for asynchronous execution and returns immediately.
     
     - parameter closure: The closure to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func async(_ closure: @escaping () -> Void) -> GCDBlock {
        
        return self.async(GCDBlock(closure))
    }
    
    /**
     Submits a block for asynchronous execution and returns immediately.
     
     - parameter block: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func async(_ block: GCDBlock) -> GCDBlock {
        
        self.dispatchQueue().async(execute: block.dispatchBlock())
        return block
    }
    
    /**
     Submits a closure for execution and waits until that block completes.
     
     - parameter closure: The closure to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func sync(_ closure: @escaping () -> Void) -> GCDBlock {
        
        return self.sync(GCDBlock(closure))
    }
    
    /**
     Submits a block object for execution on a dispatch queue and waits until that block completes.
     
     - parameter block: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func sync(_ block: GCDBlock) -> GCDBlock {
        
        self.dispatchQueue().sync(execute: block.dispatchBlock())
        return block
    }
    
    /**
     Enqueue a closure for execution after a specified delay.
     
     - parameter delay: The number of seconds delay before executing the closure
     - parameter closure: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func after(_ delay: TimeInterval, _ closure: @escaping () -> Void) -> GCDBlock {
        
        return self.after(delay, GCDBlock(closure))
    }
    
    /**
     Enqueue a block for execution after a specified delay.
     
     - parameter delay: The number of seconds delay before executing the block
     - parameter block: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func after(_ delay: TimeInterval, _ block: GCDBlock) -> GCDBlock {
        
        self.dispatchQueue().asyncAfter(
            deadline: DispatchTime.now() + delay,
            execute: block.dispatchBlock()
        )
        return block
    }
    
    /**
     Submits a barrier closure for asynchronous execution and returns immediately.
     
     - parameter closure: The closure to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func barrierAsync(_ closure: @escaping () -> Void) -> GCDBlock {
        
        return self.barrierAsync(GCDBlock(closure))
    }
    
    /**
     Submits a barrier block for asynchronous execution and returns immediately.
     
     - parameter closure: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func barrierAsync(_ block: GCDBlock) -> GCDBlock {
        
        self.dispatchQueue().async(flags: .barrier, execute: block.dispatchBlock().perform)
        return block
    }
    
    /**
     Submits a barrier closure for execution and waits until that block completes.
     
     - parameter closure: The closure to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func barrierSync(_ closure: @escaping () -> Void) -> GCDBlock {
        
        return self.barrierSync(GCDBlock(closure))
    }
    
    /**
     Submits a barrier block for execution and waits until that block completes.
     
     - parameter closure: The block to submit.
     - returns: The block to submit. Useful when chaining blocks together.
     */
    @discardableResult
    public func barrierSync(_ block: GCDBlock) -> GCDBlock {
        
        self.dispatchQueue().sync(flags: .barrier, execute: block.dispatchBlock().perform)
        return block
    }
    
    /**
     Submits a closure for multiple invocations.
     
     - parameter iterations: The number of iterations to perform.
     - parameter closure: The closure to submit.
     */
    public func apply<T: UnsignedInteger>(_ iterations: T, _ closure: @escaping (_ iteration: T) -> Void) {
        
        let group = DispatchGroup()
        for iteration in stride(from: 0, to: iterations, by: 1) {
            
            self.dispatchQueue().async(group: group) {
                
                closure(iteration)
            }
        }
        group.wait()
    }
    
    /**
     Checks if the queue is the current execution context. Global queues other than the main queue are not supported and will always return nil.
     
     - returns: true if the queue is the current execution context, or false if it is not.
     */
    public func isCurrentExecutionContext() -> Bool {
        
        let dispatchQueue = self.dispatchQueue()
        let specific = ObjectIdentifier(dispatchQueue)

        dispatchQueue.setSpecific(key: _GCDQueue_Specific, value: specific)
        return DispatchQueue.getSpecific(key: _GCDQueue_Specific) == specific
    }
    
    /**
     Returns the dispatch_queue_t object associated with this value.
     
     - returns: The dispatch_queue_t object associated with this value.
     */
    public func dispatchQueue() -> DispatchQueue {
        
        switch self {
            
        case .main:
            return DispatchQueue.main
            
        case .userInteractive:
            return DispatchQueue.global(qos: .userInteractive)
            
        case .userInitiated:
            return DispatchQueue.global(qos: .userInitiated)
            
        case .default:
            return DispatchQueue.global(qos: .default)
            
        case .utility:
            return DispatchQueue.global(qos: .utility)
            
        case .background:
            return DispatchQueue.global(qos: .background)
            
        case .custom(let rawObject):
            return rawObject
        }
    }
    
    fileprivate static func createCustom(_ isConcurrent: Bool, label: String?, targetQueue: GCDQueue?) -> GCDQueue {
        
        let queue = GCDQueue.custom(
            DispatchQueue(
                label: label ?? "",
                attributes: (isConcurrent ? .concurrent : [])
            )
        )
        if let target = targetQueue {
            
            queue.dispatchQueue().setTarget(queue: target.dispatchQueue())
        }
        return queue
    }
}

public func == (lhs: GCDQueue, rhs: GCDQueue) -> Bool {
    
    switch (lhs, rhs) {
        
    case (.main, .main):
        return true
        
    case (.userInteractive, .userInteractive):
        return true
        
    case (.userInitiated, .userInitiated):
        return true
        
    case (.default, .default):
        return true
        
    case (.utility, .utility):
        return true
        
    case (.background, .background):
        return true
        
    case (.custom(let lhsRawObject), .custom(let rhsRawObject)):
        return lhsRawObject === rhsRawObject
        
    default:
        return false
    }
}

extension GCDQueue: Equatable { }
