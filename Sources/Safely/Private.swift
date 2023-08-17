//
//  Private.swift
//  
//
//  Created by Brandon Sneed on 2/4/23.
//

import Foundation

// MARK: Internal Swift stuff we need

@_silgen_name ("setjmp")
public func setjump(_: UnsafeMutablePointer<jmp_buf>) -> Int32

@_silgen_name ("longjmp")
public func longjump(_: UnsafeMutablePointer<jmp_buf>, _: Int32) -> Never

#if !os(Linux) && !os(Windows)
import SafelyInternal
public func SACatchException(_ block: () -> Void) -> NSException? {
    return SafelyInternal.SACatchException {
        block()
    }
}
#else
public func SACatchException(_ block: () -> Void) -> NSException? {
    block()
    return nil
}
#endif

// MARK: Uncaught Exceptions

#if !os(Linux) && !os(Windows)
internal func uncaughtExceptionHandler(enabled: Bool) {
    if enabled == false {
        SAClearUncaughtExceptionHandler()
    } else {
        SASetUncaughtExceptionHandler { exception in
            let e = ExceptionError(exception: exception)
            uncaughtExceptionHandler(error: e)
        }
    }
}

internal func uncaughtExceptionHandler(error: Error) {
    Safely.escape(error: error)
}

#endif

// MARK: Signals

internal func signalHandler(enabled: Bool) {
    if enabled {
        signal(SIGILL, _signalHandler)
        signal(SIGABRT, _signalHandler)
        signal(SIGTRAP, _signalHandler)
        #if DEBUG
        signal(SIGALRM, _signalHandler)
        #endif
    } else {
        // clear the signal handlers
        signal(SIGILL, nil)
        signal(SIGABRT, nil)
        signal(SIGTRAP, nil)
        #if DEBUG
        signal(SIGALRM, _signalHandler)
        #endif
    }
}

internal func _signalHandler(_ signal: Int32) -> Void {
    let e = SignalError(signal: signal)
    Safely.escape(error: e)
}


// MARK: Assertions

internal func assertionHandler(enabled: Bool) {
    if enabled {
        // For Swift 5.3+, also hook _assertionFailure which gives file and line
        let failure = "_assertionFailure__4file4line5flagss5NeverOs12StaticStringV_A2"
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        
        if let _ = dlsym(RTLD_DEFAULT, "hook_assertionFailure") {
            print("found")
        }
        
        if let fake = dlsym(RTLD_DEFAULT, "hook_assertionFailure") {
            var rebindings = [rebinding(name: strdup("$ss17"+failure+"HSus6UInt32VtF"),
                                        replacement: fake, replaced: nil)]
            rebind_symbols(&rebindings, rebindings.count)
            free(UnsafeMutablePointer(mutating: rebindings[0].name))
        }
    }
}

@_silgen_name ("hook_assertionFailure")
public func hook_assertionFailure(
  _ prefix: StaticString, _ message: StaticString,
  file: StaticString, line: UInt,
  flags: UInt32
) -> Never {
    Safely.escape(error: AssertionError(prefix: "\(prefix)", message: "\(message)", file: "\(file)", line: line))
}


// MARK: Utilities

private var exclusivityChecking = false
internal func exclusivityChecking(enable: Bool) {
    if exclusivityChecking == enable { return }
    guard let handle = dlopen(nil, Int32(RTLD_LAZY | RTLD_NOLOAD)) else { return }
    guard let value = dlsym(handle, "_swift_disableExclusivityChecking") else { return }
    value.assumingMemoryBound(to: Bool.self).pointee = enable
}

// MARK: Locking

import os.lock

class UnfairLock {
    func lock() {
        os_unfair_lock_lock(oslock)
    }
    
    func unlock() {
        os_unfair_lock_unlock(oslock)
    }
    
    func trylock() -> Bool {
        return os_unfair_lock_trylock(oslock)
    }
    
    let oslock = {
        let lockPtr = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lockPtr.initialize(to: .init())
        return lockPtr
    }()
    
    deinit {
        oslock.deinitialize(count: 1)
        oslock.deallocate()
    }
}

