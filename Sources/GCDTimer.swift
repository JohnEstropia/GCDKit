//
//  GCDTimer.swift
//  GCDKit
//
//  Copyright © 2015 John Rommel Estropia
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
A wrapper and utility class for dispatch_source_t of type DISPATCH_SOURCE_TYPE_TIMER.
*/
@available(iOS, introduced=7.0)
public final class GCDTimer {
    
    /**
    Creates a suspended timer. Call the resume() method to start the timer.
    
    - parameter queue: The queue to which the timer will execute the closure on.
    - parameter interval: The tick duration for the timer in seconds.
    - parameter closure: The closure to submit to the timer queue.
    - returns: The created suspended timer.
    */
    public class func createSuspended(queue: GCDQueue, interval: NSTimeInterval, eventHandler: (timer: GCDTimer) -> Void) -> GCDTimer {
        
        let timer = GCDTimer(queue: queue)
        timer.setTimer(interval)
        timer.setEventHandler(eventHandler)
        return timer
    }
    
    /**
    Creates an auto-start timer. The resume() method does not need to be called after this method returns.
    
    - parameter queue: The queue to which the timer will execute the closure on.
    - parameter interval: The tick duration for the timer in seconds.
    - parameter closure: The closure to submit to the timer queue.
    - returns: The created auto-start timer.
    */
    public class func createAutoStart(queue: GCDQueue, interval: NSTimeInterval, eventHandler: (timer: GCDTimer) -> Void) -> GCDTimer {
        
        let timer = GCDTimer(queue: queue)
        timer.setTimer(interval)
        timer.setEventHandler(eventHandler)
        timer.resume()
        return timer
    }
    
    /**
    Resumes/starts the timer. Does nothing if the timer is already running.
    */
    public func resume() {
        
        var isSuspended = false
        dispatch_barrier_sync(self.barrierQueue) {
            
            isSuspended = self.isSuspended
            if isSuspended {
                
                self.isSuspended = false
            }
        }
        
        if !isSuspended {
            
            return
        }
        
        dispatch_resume(self.rawObject)
    }
    
    /**
    Suspends the timer. Does nothing if the timer is already suspended.
    */
    public func suspend() {
        
        var isSuspended = false
        dispatch_barrier_sync(self.barrierQueue) {
            
            isSuspended = self.isSuspended
            if !isSuspended {
                
                self.isSuspended = true
            }
        }
        
        if isSuspended {
            
            return
        }
        
        dispatch_suspend(self.rawObject)
    }
    
    /**
    Sets a timer relative to the default clock.
    */
    public func setTimer(interval: NSTimeInterval) {
        
        self.setTimer(interval, leeway: 0.0)
    }
    
    /**
    Sets a timer relative to the default clock.
    */
    public func setTimer(interval: NSTimeInterval, leeway: NSTimeInterval) {
        
        let deltaTime = interval * NSTimeInterval(NSEC_PER_SEC)
        dispatch_source_set_timer(
            self.rawObject,
            dispatch_time(DISPATCH_TIME_NOW, Int64(deltaTime)),
            UInt64(deltaTime),
            UInt64(leeway * NSTimeInterval(NSEC_PER_SEC)))
    }
    
    /**
    Sets a timer using an absolute time according to the wall clock.
    */
    public func setWallTimer(startDate startDate: NSDate, interval: NSTimeInterval){
        
        self.setWallTimer(startDate: startDate, interval: interval, leeway: 0.0)
    }
    
    /**
    Sets a timer using an absolute time according to the wall clock.
    */
    public func setWallTimer(startDate startDate: NSDate, interval: NSTimeInterval, leeway: NSTimeInterval){
        
        var walltime = startDate.timeIntervalSince1970.toTimeSpec()
        let deltaTime = interval * NSTimeInterval(NSEC_PER_SEC)
        dispatch_source_set_timer(
            self.rawObject,
            dispatch_walltime(&walltime, Int64(deltaTime)),
            UInt64(deltaTime),
            UInt64(leeway * NSTimeInterval(NSEC_PER_SEC)))
    }
    
    /**
    Sets the event handler for the timer.
    */
    public func setEventHandler(eventHandler: (timer: GCDTimer) -> Void) {
        
        dispatch_source_set_event_handler(self.rawObject) { [weak self] in
            
            guard let strongSelf = self else {
                
                return
            }
            
            autoreleasepool {
                
                eventHandler(timer: strongSelf)
            }
        }
    }
    
    /**
    Returns the true if the timer is running, or false otherwise.
    */
    public var isRunning: Bool {
        
        var isSuspended = false
        dispatch_barrier_sync(self.barrierQueue) {
            
            isSuspended = self.isSuspended
        }
        return !isSuspended
    }
    
    /**
    Returns the dispatch_source_t object associated with the timer.
    
    - returns: The dispatch_source_t object associated with the timer.
    */
    public func dispatchSource() -> dispatch_source_t {
        
        return self.rawObject
    }
    
    private init(queue: GCDQueue) {
        
        let dispatchTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue.dispatchQueue())
        
        self.queue = queue
        self.rawObject = dispatchTimer
        self.barrierQueue = dispatch_queue_create("com.GCDTimer.barrierQueue", DISPATCH_QUEUE_CONCURRENT)
        self.isSuspended = true
    }
    
    deinit {
        
        self.setEventHandler { (_) -> Void in }
        self.resume()
        dispatch_source_cancel(self.rawObject)
    }
    
    private let queue: GCDQueue
    private let rawObject: dispatch_source_t
    private let barrierQueue: dispatch_queue_t
    private var isSuspended: Bool
}


private extension NSTimeInterval {
    
    private func toTimeSpec() -> timespec {
        
        var seconds: NSTimeInterval = 0.0
        let fractionalPart = modf(self, &seconds)
        
        let nanoSeconds = fractionalPart * NSTimeInterval(NSEC_PER_SEC)
        return timespec(tv_sec: __darwin_time_t(seconds), tv_nsec: Int(nanoSeconds))
    }
}
