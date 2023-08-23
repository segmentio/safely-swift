//
//  Safely.swift
//  
//
//  Created by Brandon Sneed on 2/15/23.
//

#if !os(Linux) && !os(Windows)

import Foundation
import SafelyInternal

public class Safely {
    /// Optionally log safe call errors to the developer console
    static public var logErrorsToConsole: Bool = false
    /// Handle errors in a more global way; closure is executed when errors occur.
    static public var onError: ((Error) -> Void)? = nil
    
    static public var handleThrows: Bool = true 
    static public var handleExceptions: Bool = true {
        didSet {
            uncaughtExceptionHandler(enabled: handleExceptions)
        }
    }
    static public var handleSignals: Bool = false {
        didSet {
            // need this for execution stack unwind capabilities
            exclusivityChecking(enable: handleSignals)
            signalHandler(enabled: handleSignals)
        }
    }
    static public var handleAssertions: Bool = false {
        didSet {
            // need this for execution stack unwind capabilities
            exclusivityChecking(enable: handleAssertions)
            assertionHandler(enabled: true)
        }
    }

    @discardableResult
    static public func call<T>(scenario: SafeScenario, context: T, _ closure: (T) throws -> Void) -> Error? {
        let local = safelyThread
        
        executionBuffer.withUnsafeBytes { buffer in
            let pointer = buffer.baseAddress!.assumingMemoryBound(to: jmp_buf.self)
            local.stack.append(pointer.pointee)
        }
        
        defer {
            local.stack.removeLast()
        }
        
        if setjump(&local.stack[local.stack.count - 1]) != 0 {
            return local.error ?? NSError(domain: "Execution stack is empty!", code: -1)
        }
        
        var result: Error? = nil
        let runner: (((T) throws -> Void)) -> Void = { closure in
            do {
                try closure(context)
            } catch {
                if Safely.handleThrows {
                    result = error
                }
            }
        }
        
        if Safely.handleExceptions {
            let exception = SACatchException { runner(closure) }
            if let e = exception {
                result = ExceptionError(exception: e)
            }
        } else {
            runner(closure)
        }
        
        return result
    }
    
    static public func catchCall<T>(scenario: SafeScenario, context: T, _ closure: (T) throws -> Void) throws {
        if let e = call(scenario: scenario, context: context, closure) {
            throw e
        }
    }
    
    // MARK: - Internal
    
    internal required init() {}
    
    static var keyLock = UnfairLock()
    static private var pthreadKey: pthread_key_t = 0
    static var threadKeyPointer: UnsafeMutablePointer<pthread_key_t> {
        return UnsafeMutablePointer(&pthreadKey)
    }

    static var safelyThread: Self {
        // We need a per-thread instance of Safely to store our execution stack.
        // This accomplishes that task by setting an instance on the pthread itself
        // and putting access to it in a lock.
        let keyVar = threadKeyPointer
        keyLock.lock()
        // create a slot for our new key if we need to.
        if keyVar.pointee == 0 {
            let result = pthread_key_create(keyVar, {
                Unmanaged<Safely>.fromOpaque($0).release()
            })
            if result != 0 {
                fatalError("Could not pthread_key_create: \(String(cString: strerror(result)))")
            }
        }
        
        defer {
            // make sure we've set it below before we release the lock; tell
            // this to run at the end via defer.
            keyLock.unlock()
        }
        
        // see if we have an existing key holding our self value
        if let existing = pthread_getspecific(keyVar.pointee) {
            // we do, so return that.
            return Unmanaged<Self>.fromOpaque(existing).takeUnretainedValue()
        }
        else {
            // we have a key, but it's not set, so give it a value.
            let unmanaged = Unmanaged.passRetained(Self())
            let result = pthread_setspecific(keyVar.pointee, unmanaged.toOpaque())
            if result != 0 {
                fatalError("Could not pthread_setspecific: \(String(cString: strerror(result)))")
            }
            return unmanaged.takeUnretainedValue()
        }
    }
    
    internal var stack = [jmp_buf]()
    internal var error: Error? = nil
    
    static internal let executionBuffer = [UInt8](repeating: 0, count: MemoryLayout<jmp_buf>.size)
    
    static internal func escape(error: Error) -> Never {
        let local = safelyThread
        local.error = error
        
        if local.stack.count == 0 {
            // we have no execution stack for some reason... very unlikely, sun spots/flares?? :D 
            longjump(&local.stack[0], 1)
        } else {
            // we're going to unwind the execution stack back to the last known
            // good place just before where we entered into escape.
            longjump(&local.stack[local.stack.count - 1], 1)
        }
    }
}

#else

// NOTE: Linux version - for the sake of compatibility only, not terribly useful on linux tbh.

public class Safely {
    /// Optionally log safe call errors to the developer console
    static public var logErrorsToConsole: Bool = false
    /// Handle errors in a more global way; closure is executed when errors occur.
    static public var onError: ((Error) -> Void)? = nil
    
    static public var handleThrows: Bool = true
    static public var handleExceptions: Bool = false
    static public var handleSignals: Bool = false
    static public var handleAssertions: Bool = false
    
    @discardableResult
    static public func call<T>(scenario: SafeScenario, context: T, _ closure: (T) throws -> Void) -> Error? {
        var result: Error? = nil
        let runner: (((T) throws -> Void)) -> Void = { closure in
            do {
                try closure(context)
            } catch {
                if Safely.handleThrows {
                    result = error
                }
            }
        }
        
        runner(closure)
        
        return result
    }
    
    static public func catchCall<T>(scenario: SafeScenario, context: T, _ closure: (T) throws -> Void) throws {
        if let e = call(scenario: scenario, context: context, closure) {
            throw e
        }
    }
    
    internal required init() {}
}
#endif
