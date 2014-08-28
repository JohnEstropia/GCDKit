//
//  DispatchKitTests.swift
//  DispatchKitTests
//
//  Created by John Rommel Estropia on 2014/08/24.
//  Copyright (c) 2014 John Rommel Estropia. All rights reserved.
//

import DispatchKit
import XCTest

class DispatchKitTests: XCTestCase {
    
    func testMainQueue() {
        
        let queue = GCDQueue.Main
        XCTAssertNotNil(queue.dispatchObject());
        XCTAssertEqual(queue.dispatchObject(), dispatch_get_main_queue())
        
        var didStartWaiting = false
        let dispatchExpectation = self.expectationWithDescription("main queue block")
        GCDQueue.Main.async {
            
            XCTAssertTrue(didStartWaiting)
            XCTAssertTrue(NSThread.isMainThread())
            dispatchExpectation.fulfill()
        }
        
        didStartWaiting = true
        self.waitForExpectationsWithTimeout(1.0, nil)
    }
    
    func testGlobalQueue() {
        
        XCTAssertNotNil(GCDQueue.Default.dispatchObject());
        
        var didStartWaiting = false
        let dispatchExpectation = self.expectationWithDescription("global queue block")
        GCDQueue.Default.async {
            
            XCTAssertTrue(didStartWaiting)
            XCTAssertTrue(!NSThread.isMainThread())
            dispatchExpectation.fulfill()
        }
        
        didStartWaiting = true
        self.waitForExpectationsWithTimeout(1.0, nil)
    }
    
    func testDispatchGroup() {
        
        let group = GCDGroup()
        XCTAssertNotNil(group.dispatchObject());
        
        let expectation1 = self.expectationWithDescription("dispatch group block 1")
        group.async(.Main) {
            
            XCTAssertTrue(NSThread.isMainThread())
            expectation1.fulfill()
        }
        
        let expectation2 = self.expectationWithDescription("dispatch group block 2")
        group.enter()
        GCDQueue.Utility.after(3.0) {
            
            XCTAssertTrue(!NSThread.isMainThread())
            expectation2.fulfill()
            group.leave()
        }
        
        let expectation3 = self.expectationWithDescription("dispatch group block 3")
        group.enter()
        GCDQueue.Default.async {
            
            XCTAssertTrue(!NSThread.isMainThread())
            expectation3.fulfill()
            group.leave()
        }
        
        let expectation4 = self.expectationWithDescription("dispatch group block 4")
        group.notify(.Default) {
            
            XCTAssertTrue(!NSThread.isMainThread())
            expectation4.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, nil)
    }
    
    func testSemaphore() {
        
        let semaphore = GCDSemaphore(1)
        XCTAssertNotNil(semaphore.dispatchObject());
        
        var didStartWaiting = false
        let expectation = self.expectationWithDescription("semaphore block")
        GCDQueue.Default.after(3.0) {
            
            XCTAssertTrue(didStartWaiting)
            XCTAssertTrue(!NSThread.isMainThread())
            XCTAssertTrue(semaphore.signal() == 0)
            expectation.fulfill()
        }
        
        didStartWaiting = true
        XCTAssertTrue(semaphore.wait() == 0)
        
        self.waitForExpectationsWithTimeout(4.0, nil)
    }
    
}
