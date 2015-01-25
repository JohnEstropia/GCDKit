//
//  GCDKitTests.swift
//  GCDKitTests
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

import GCDKit
import XCTest

class GCDKitTests: XCTestCase {
    
    func testGCDBlocks() {
        
        var didStartWaiting = false
        var finishedTasks = 0
        let expectation1 = self.expectationWithDescription("dispatch block 1")
        let expectation2 = self.expectationWithDescription("dispatch block 2")
        let expectation3 = self.expectationWithDescription("dispatch block 3")
        GCDBlock.async(.Background) {
            
            XCTAssertTrue(finishedTasks == 0)
            XCTAssertTrue(didStartWaiting)
            XCTAssertFalse(NSThread.isMainThread())
            XCTAssertTrue(GCDQueue.Background.isCurrentExecutionContext())
            expectation1.fulfill()
            
            finishedTasks++
        }
        .notify(.Default) {
            
            XCTAssertTrue(finishedTasks == 1)
            XCTAssertFalse(NSThread.isMainThread())
            XCTAssertTrue(GCDQueue.Default.isCurrentExecutionContext())
            expectation2.fulfill()
            
            finishedTasks++
        }
        .notify(.Main) {
            
            XCTAssertTrue(finishedTasks == 2)
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertTrue(GCDQueue.Main.isCurrentExecutionContext())
            expectation3.fulfill()
        }
        
        didStartWaiting = true
        self.waitForExpectationsWithTimeout(5.0, nil)
    }
    
    func testGCDQueue() {
        
        let queue = GCDQueue.Main
        XCTAssertNotNil(queue.dispatchQueue());
        XCTAssertEqual(queue.dispatchQueue(), dispatch_get_main_queue())
        
        let allQueues: [GCDQueue] = [.Main, .UserInteractive, .UserInitiated, .Default, .Utility, .Background, .createSerial("serial"), .createConcurrent("serial")]
        var allQueuesExpectations = [XCTestExpectation]()
        for queue in allQueues {
            
            let dispatchExpectation = self.expectationWithDescription("main queue block")
            allQueuesExpectations.append(dispatchExpectation)
            
            queue.async {
                
                XCTAssertTrue(queue.isCurrentExecutionContext())
                if !queue.isCurrentExecutionContext() {
                    
                    NSLog("** \(queue) \(qos_class_self().value)")
                }
                for otherQueue in allQueues {
                    
                    if queue != otherQueue {
                        
                        XCTAssertFalse(otherQueue.isCurrentExecutionContext())
                        if otherQueue.isCurrentExecutionContext() {
                            
                            NSLog("** \(queue): \(otherQueue) \(qos_class_self().value)")
                        }
                    }
                }
                dispatchExpectation.fulfill()
            }
        }
        
        var didStartWaiting = false
        let dispatchExpectation = self.expectationWithDescription("main queue block")
        GCDQueue.Background.async {
            
            XCTAssertTrue(didStartWaiting)
            XCTAssertFalse(NSThread.isMainThread())
            dispatchExpectation.fulfill()
        }
        
        didStartWaiting = true
        self.waitForExpectationsWithTimeout(5.0, nil)
    }
    
    func testGCDGroup() {
        
        let group = GCDGroup()
        XCTAssertNotNil(group.dispatchGroup());
        
        let expectation1 = self.expectationWithDescription("dispatch group block 1")
        let expectation2 = self.expectationWithDescription("dispatch group block 2")
        group.async(.Main) {
            
            XCTAssertTrue(NSThread.isMainThread())
            expectation1.fulfill()
        }
        .async(.Default) {
            
            XCTAssertFalse(NSThread.isMainThread())
            expectation2.fulfill()
        }
        
        let expectation3 = self.expectationWithDescription("dispatch group block 3")
        group.enter()
        GCDQueue.Utility.after(3.0) {
            
            XCTAssertFalse(NSThread.isMainThread())
            expectation3.fulfill()
            group.leave()
        }
        
        let expectation4 = self.expectationWithDescription("dispatch group block 4")
        group.enter()
        GCDQueue.Default.async {
            
            XCTAssertFalse(NSThread.isMainThread())
            expectation4.fulfill()
            group.leave()
        }
        
        let expectation5 = self.expectationWithDescription("dispatch group block 5")
        group.notify(.Default) {
            
            XCTAssertFalse(NSThread.isMainThread())
            expectation5.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, nil)
    }
    
    func testGCDSemaphore() {
        
        let numberOfTasks: UInt = 10
        let semaphore = GCDSemaphore(numberOfTasks)
        XCTAssertNotNil(semaphore.dispatchSemaphore());
        
        var expectations = [XCTestExpectation]();
        for i in 0 ..< numberOfTasks {
        
            expectations.append(self.expectationWithDescription("semaphore block \(i)"))
        }
        
        let queue = GCDQueue.createConcurrent("testGCDSemaphore.queue")
        queue.apply(numberOfTasks) { (iteration: UInt) -> Void in
            
            XCTAssertTrue(queue.isCurrentExecutionContext())
            expectations[Int(iteration)].fulfill()
            semaphore.signal()
        }
        
        semaphore.wait()
        
        self.waitForExpectationsWithTimeout(0.0, nil)
    }
    
    func testGCDTimer() {
        
        var runningExpectations = [XCTestExpectation]()
        let numberOfTicksToTest = 10
        for i in 0..<numberOfTicksToTest {
            
            runningExpectations.append(self.expectationWithDescription("timer tick \(i)"))
        }
        let suspendExpectation = self.expectationWithDescription("timer suspended")
        
        var previousTimestamp = NSDate().timeIntervalSince1970
        var iteration = 0.0
        let timer = GCDTimer.createAutoStart(.Default, interval: (1.0 * (iteration + 1.0))) { (timer) -> Void in
            
            XCTAssertTrue(GCDQueue.Default.isCurrentExecutionContext())
            
            let currentTimestamp = NSDate().timeIntervalSince1970
            XCTAssertGreaterThanOrEqual(currentTimestamp - previousTimestamp, (1.0 * (iteration + 1.0)), "Timer fired before expected time")
            XCTAssertTrue(timer.isRunning, "Timer's isRunning property is not true")
            
            previousTimestamp = currentTimestamp
            
            if Int(iteration) < runningExpectations.count {
                
                runningExpectations[Int(iteration)].fulfill()
            }
            else {
                
                timer.suspend()
                XCTAssertFalse(timer.isRunning, "Timer's isRunning property is not false")
                suspendExpectation.fulfill()
            }
            
            iteration++
            timer.setTimeInterval(1.0 * (iteration + 1.0))
        }
        XCTAssertTrue(timer.isRunning, "Timer's isRunning property is not true")
        
        let numberOfTicks = NSTimeInterval(numberOfTicksToTest) + 1
        self.waitForExpectationsWithTimeout((numberOfTicks * (numberOfTicks / 2.0 + 1.0)) + 5.0, nil)
    }
}
