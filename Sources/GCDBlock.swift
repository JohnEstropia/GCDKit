//
//  GCDBlock.swift
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
 A wrapper and utility class for dispatch_block_t.
 */
public struct GCDBlock {
    
    /**
     Create a new block object on the heap from a closure.
     
     - parameter closure: The closure to be associated with the block.
     */
    public init(_ closure: @escaping () -> Void) {
        
        self.rawObject = DispatchWorkItem(flags: .inheritQoS, block: closure)
    }
    
    /**
     Submits a closure for asynchronous execution on a queue and returns immediately.
     
     - parameter queue: The queue to which the supplied block will be submitted.
     - parameter closure: The closure to submit to the target queue.
     - returns: The block to submit to the queue. Useful when chaining blocks together.
     */
    @discardableResult
    public static func async(_ queue: GCDQueue, closure: @escaping () -> Void) -> GCDBlock {
        
        return queue.async(closure)
    }
    
    /**
     Submits a closure for execution on a queue and waits until that block completes.
     
     - parameter queue: The queue to which the supplied block will be submitted.
     - parameter closure: The closure to submit to the target queue.
     - returns: The block to submit to the queue. Useful when chaining blocks together.
     */
    @discardableResult
    public static func sync(_ queue: GCDQueue, closure: @escaping () -> Void) -> GCDBlock {
        
        return queue.sync(closure)
    }
    
    /**
     Enqueue a closure for execution at the specified time.
     
     - parameter queue: The queue to which the supplied block will be submitted.
     - parameter delay: The number of seconds delay before executing the block
     - parameter closure: The closure to submit to the target queue.
     - returns: The block to submit to the queue. Useful when chaining blocks together.
     */
    @discardableResult
    public static func after(_ queue: GCDQueue, delay: TimeInterval, _ closure: @escaping () -> Void) -> GCDBlock {
        
        return queue.after(delay, closure)
    }
    
    /**
     Submits a barrier closure for asynchronous execution and returns immediately.
     
     - parameter queue: The queue to which the supplied block will be submitted.
     - parameter closure: The closure to submit to the target queue.
     - returns: The block to submit to the queue. Useful when chaining blocks together.
     */
    @discardableResult
    public static func barrierAsync(_ queue: GCDQueue, closure: @escaping () -> Void) -> GCDBlock {
        
        return queue.barrierAsync(closure)
    }
    
    /**
     Submits a barrier closure object for execution and waits until that block completes.
     
     - parameter queue: The queue to which the supplied block will be submitted.
     - parameter closure: The closure to submit to the target queue.
     - returns: The block to submit to the queue. Useful when chaining blocks together.
     */
    @discardableResult
    public static func barrierSync(_ queue: GCDQueue, closure: @escaping () -> Void) -> GCDBlock {
        
        return queue.barrierSync(closure)
    }
    
    /**
     Synchronously executes the block.
     */
    public func perform() {
        
        self.rawObject.perform()
    }
    
    /**
     Schedule a notification closure to be submitted to a queue when the execution of the block has completed.
     
     - parameter queue: The queue to which the supplied notification closure will be submitted when the block completes.
     - parameter closure: The notification closure to submit when the block completes.
     - returns: The notification block. Useful when chaining blocks together.
     */
    @available(iOS 8.0, OSX 10.10, *)
    @discardableResult
    public func notify(_ queue: GCDQueue, closure: @escaping () -> Void) -> GCDBlock {
        
        let block = GCDBlock(closure)
        self.rawObject.notify(queue: queue.dispatchQueue(), execute: block.rawObject)
        return block
    }
    
    /**
     Asynchronously cancel the block.
     */
    @available(iOS 8.0, OSX 10.10, *)
    public func cancel() {
        
        self.rawObject.cancel()
    }
    
    /**
     Wait synchronously until execution of the block @available(iOS 8.0, OSX 10.10, *)
     has completed.
     */
    @available(iOS 8.0, OSX 10.10, *)
    public func wait() {
        
        self.rawObject.wait()
    }
    
    /**
     Wait synchronously until execution of the block has completed or until the specified timeout has elapsed.
     
     - parameter timeout: The number of seconds before timeout.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
     */
    @available(iOS 8.0, OSX 10.10, *)
    public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
        
        return self.rawObject.wait(timeout: DispatchTime.now() + timeout)
    }
    
    /**
     Wait synchronously until execution of the block has completed or until the specified timeout has elapsed.
     
     - parameter date: The timeout date.
     - returns: Returns `.Success` on success, or `.TimedOut` if the timeout occurred.
     */
    @available(iOS 8.0, OSX 10.10, *)
    public func wait(_ date: Date) -> DispatchTimeoutResult {
        
        return self.wait(date.timeIntervalSinceNow)
    }
    
    /**
     Returns the dispatch_block_t object associated with this value.
     
     - returns: The dispatch_block_t object associated with this value.
     */
    public func dispatchBlock() -> DispatchWorkItem {
        
        return self.rawObject
    }
    
    fileprivate let rawObject: DispatchWorkItem
}
