//
//  GCDBlock.swift
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

/**
A wrapper and utility class for dispatch_block_t.
*/
@availability(iOS, introduced=8.0)
public struct GCDBlock {
    
    /**
    Create a new block object on the heap from a closure.
    
    :param: closure The closure to be associated with the block.
    */
    public init(closure: () -> ()) {
        
        self.rawObject = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            
            autoreleasepool(closure)
        }
    }
    
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
}
