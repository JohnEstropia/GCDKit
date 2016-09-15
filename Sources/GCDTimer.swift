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
public final class GCDTimer {
    
    /**
    Creates a suspended timer. Call the resume() method to start the timer.
    
    - parameter queue: The queue to which the timer will execute the closure on.
    - parameter interval: The tick duration for the timer in seconds.
    - parameter closure: The closure to submit to the timer queue.
    - returns: The created suspended timer.
    */
    public class func createSuspended(_ queue: GCDQueue, interval: DispatchTimeInterval, eventHandler: @escaping (_ timer: GCDTimer) -> Void) -> GCDTimer {
        
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
    public class func createAutoStart(_ queue: GCDQueue, interval: DispatchTimeInterval, eventHandler: @escaping (_ timer: GCDTimer) -> Void) -> GCDTimer {
        
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
        self.barrierQueue.sync {
            
            isSuspended = self.isSuspended
            if isSuspended {
                
                self.isSuspended = false
            }
        }
        
        if !isSuspended {
            
            return
        }
        
        self.rawObject.resume()
    }
    
    /**
    Suspends the timer. Does nothing if the timer is already suspended.
    */
    public func suspend() {
        
        var isSuspended = false
        self.barrierQueue.sync {
            
            isSuspended = self.isSuspended
            if !isSuspended {
                
                self.isSuspended = true
            }
        }
        
        if isSuspended {
            
            return
        }
        
        self.rawObject.suspend()
    }
    
    /**
    Sets a timer relative to the default clock.
    */
    public func setTimer(_ interval: DispatchTimeInterval) {
        
        self.setTimer(interval, leeway: .microseconds(0))
    }
    
    /**
    Sets a timer relative to the default clock.
    */
    public func setTimer(_ interval: DispatchTimeInterval, leeway: DispatchTimeInterval) {
        
        self.rawObject.scheduleRepeating(
            deadline: DispatchTime.now() + interval,
            interval: interval,
            leeway: leeway
        )
    }
    
    /**
    Sets a timer using an absolute time according to the wall clock.
    */
    public func setWallTimer(_ startDate: Date, interval: DispatchTimeInterval) {
        
        self.setWallTimer(startDate, interval: interval, leeway: .microseconds(0))
    }
    
    /**
    Sets a timer using an absolute time according to the wall clock.
    */
    public func setWallTimer(_ startDate: Date, interval: DispatchTimeInterval, leeway: DispatchTimeInterval) {
        
        self.rawObject.scheduleRepeating(
            wallDeadline: DispatchWallTime(timespec: startDate.timeIntervalSince1970.toTimeSpec()),
            interval: interval,
            leeway: leeway
        )
    }
    
    /**
    Sets the event handler for the timer.
    */
    public func setEventHandler(_ eventHandler: @escaping (_ timer: GCDTimer) -> Void) {
        
        self.rawObject.setEventHandler { [weak self] in
            
            guard let `self` = self else {
                
                return
            }
            autoreleasepool {
                
                eventHandler(`self`)
            }
        }
    }
    
    /**
    Returns the true if the timer is running, or false otherwise.
    */
    public var isRunning: Bool {
        
        var isSuspended = false
        self.barrierQueue.sync {
            
            isSuspended = self.isSuspended
        }
        return !isSuspended
    }
    
    /**
    Returns the dispatch_source_t object associated with the timer.
    
    - returns: The dispatch_source_t object associated with the timer.
    */
    public func dispatchSource() -> DispatchSourceTimer {
        
        return self.rawObject
    }
    
    fileprivate init(queue: GCDQueue) {
        
        let dispatchTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: queue.dispatchQueue())
        
        self.queue = queue
        self.rawObject = dispatchTimer
        self.barrierQueue = DispatchQueue(label: "com.GCDTimer.barrierQueue", attributes: .concurrent)
        self.isSuspended = true
    }
    
    deinit {
        
        self.setEventHandler { (_) -> Void in }
        self.resume()
        self.rawObject.cancel()
    }
    
    fileprivate let queue: GCDQueue
    fileprivate let rawObject: DispatchSourceTimer
    fileprivate let barrierQueue: DispatchQueue
    fileprivate var isSuspended: Bool
}


private extension TimeInterval {
    
    func toTimeSpec() -> timespec {
        
        var seconds: TimeInterval = 0.0
        let fractionalPart = modf(self, &seconds)
        
        let nanoSeconds = fractionalPart * TimeInterval(NSEC_PER_SEC)
        return timespec(tv_sec: __darwin_time_t(seconds), tv_nsec: Int(nanoSeconds))
    }
}
