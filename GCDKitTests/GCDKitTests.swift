//
//  GCDKitTests.swift
//  GCDKitTests
//
//  Created by John Rommel Estropia on 2014/08/24.
//  Copyright (c) 2014 John Rommel Estropia. All rights reserved.
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
            XCTAssertNil(GCDQueue.Background.isCurrentExecutionContext())
            expectation1.fulfill()
            
            finishedTasks++
        }
        .notify(.Default) {
            
            XCTAssertTrue(finishedTasks == 1)
            XCTAssertFalse(NSThread.isMainThread())
            XCTAssertNil(GCDQueue.Default.isCurrentExecutionContext())
            expectation2.fulfill()
            
            finishedTasks++
        }
        .notify(.Main) {
            
            XCTAssertTrue(finishedTasks == 2)
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertTrue(GCDQueue.Main.isCurrentExecutionContext() ?? false)
            expectation3.fulfill()
        }
        
        didStartWaiting = true
        self.waitForExpectationsWithTimeout(5.0, nil)
    }
    
    func testGCDQueue() {
        
        let queue = GCDQueue.Main
        XCTAssertNotNil(queue.dispatchQueue());
        XCTAssertEqual(queue.dispatchQueue(), dispatch_get_main_queue())
        
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
        
        var expectations: [XCTestExpectation] = [];
        for i in 0 ..< numberOfTasks {
        
            expectations.append(self.expectationWithDescription("semaphore block \(i)"))
        }
        
        let queue = GCDQueue.createConcurrent("testGCDSemaphore.queue")
        queue.apply(numberOfTasks) { (iteration: UInt) -> () in
            
            XCTAssertTrue(queue.isCurrentExecutionContext() ?? false)
            expectations[Int(iteration)].fulfill()
            semaphore.signal()
        }
        
        semaphore.wait()
        
        self.waitForExpectationsWithTimeout(0.0, nil)
    }
    
}
