import Foundation

internal class Sync {
    /**
     Alternative to `synchronized()` that's a more manual process.
     Use like:
     ```
     func foo() {
       Sync.lock(self)
       defer { Sync.unlock(self) }
       // code in here will run once at a time, no matter how many threads get to it.
     }
     ```
     */
    class func lock(_ lock: Any) {
        objc_sync_enter(lock)
    }

    class func unlock(_ lock: Any) {
        objc_sync_exit(lock)
    }

    /**
     Use like:
     ```
     func foo() {
       Sync.synchronized(self) {
           // code in here will run once at a time, no matter how many threads get to it.
       }
     }
     ```
     */
    class func synchronized(_ lock: Any, run: () -> Void) {
        objc_sync_enter(lock)
        run()
        objc_sync_exit(lock)
    }
}
