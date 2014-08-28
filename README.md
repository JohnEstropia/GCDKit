DispatchKit
===========

DispatchKit is Grand Central Dispatch simplified with swift.

---

## Sample Usage

### GCDQueue

```swift
GCDQueue.Main.async {
    // This runs on the main queue
    assert(NSThread.isMainThread())
}

GCDQueue.Default.after(3.0) {
    // This runs on a default-level global queue after 3 seconds
    assert(!NSThread.isMainThread())
}

GCDQueue.Background.apply(10) {
   // This runs on a background quality-of-service queue 10 times
    assert(!NSThread.isMainThread())
}

let concurrentQueue = GCDQueue.createConcurrent("myCustomQueue")
concurrentQueue.barrierAsync {
    // This runs as a barrier task on the concurrent queue
    assert(!NSThread.isMainThread())
}

// Gets the dispatch_queue_t native object in case you need to get your hands dirty.
let dispatchQueue = concurrentQueue.dispatchObject()
```

### GCDGroup

```swift
let group = GCDGroup()
group.async(.Default) {
    // This runs on a default-level global queue as a dependency task for the GCDGroup
    assert(!NSThread.isMainThread())
}

group.async(.createConcurrent("myCustomQueue")) {
    // This runs on the concurrent queue as a dependency task for the GCDGroup
    assert(!NSThread.isMainThread())
}

group.notify(.Main) {
    // This runs on the main queue after all the other GCDGroup closures are complete
    assert(NSThread.isMainThread())
}

// Gets the dispatch_group_t native object in case you need to get your hands dirty.
let dispatchGroup = group.dispatchObject()
```

### GCDSemaphore

```swift
let semaphore = GCDSemaphore(10)
GCDQueue.createConcurrent("myCustomQueue").apply(10) {
    // This runs 10 parallel closures on the concurrent queue
    assert(!NSThread.isMainThread())
    semaphore.signal()
}

// Waits for all 10 tasks to complete, or until after 3 seconds
semaphore.wait(3.0)

// Gets the dispatch_semaphore_t native object in case you need to get your hands dirty.
let dispatchSemaphore = semaphore.dispatchObject()
```
