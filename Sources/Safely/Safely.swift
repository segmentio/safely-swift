//
//  Safely.swift
//  
//
//  Created by Brandon Sneed on 1/30/23.
//

import Foundation
#if !os(Linux) && !os(Windows)
import Internal
#endif

/// A options structure to control Safely's behavior.
/// 
/// Example:
/// ```
/// SafelyOptions.logErrorsToConsole = true
/// SafelyOptions.onError = { error in
///     print("ERROR: Oh noes, we got an error! \(error)")
/// }
/// ```
public struct SafelyOptions {
    /// Called if an error happens in a safe call
    static public var onError: ((Error) -> Void)? = nil
    /// Optionally log safe call errors to the developer console
    static public var logErrorsToConsole: Bool = false
    #if !os(Linux) && !os(Windows)
    /// Capture all uncaught exceptions
    static public var onUncaughtException: ((Error) -> Void)? = nil {
        didSet {
            if onUncaughtException == nil {
                SAClearUncaughtExceptionHandler()
            } else {
                SASetUncaughtExceptionHandler { exception in
                    guard let handler = onUncaughtException else { return }
                    let e = ExceptionError(exception: exception)
                    handler(e)
                }
            }
        }
    }
    #endif
}

/// Call a closure safely, capturing any unhandled exceptions from Swift or Objective-C.
///
/// Example:
/// ```
/// let context = UserDefaultsContext(userDefaults: UserDefaults(), valueToWrite: NSNull(), keyToWrite: "myNull")
/// let error = safely(scenario: Scenarios.nullPListSettings, context: context) { context in
///     let userDefaults = context.userDefaults
///     userDefaults.set(context.valueToWrite, forKey: context.keyToWrite)
/// }
/// ```
/// 
/// - Parameters:
///   - scenario: The scenario we're performing a safe call for.
///   - context: A user defined structure containing the necessary elements for the closure to operate.
///   - closure: The closure to execute safely; Accepts context as a parameter.
/// - Returns: 
///     An Error type or nil if there was no error.
@discardableResult 
public func safely<T>(scenario: SafeScenario, context: T, closure: (T) throws -> Void) -> Error? {
    var result: Error? = nil
    // I believe dispatch queue thread stacks get cleared between uses.
    // What i'm not sure about is if this is overkill or not to protect our own thread stack.
    // Thread/context switching has a performance cost.
    DispatchQueue.global(qos: .utility).sync {
        // captures an objc exception if it happens
        let exception = SACatchException {
            // captures a swift exception if it happens
            do {
                try closure(context)
            } catch {
                result = error
            }
        }
        
        if let e = exception {
            // if we got an objc exception, put it into something usable for swift.
            result = ExceptionError(exception: e)
        }
    }
    
    if let r = result {
        // we got an error of some kind, respect the options.
        if let onError = SafelyOptions.onError {
            onError(r)
        }
        if SafelyOptions.logErrorsToConsole {
            print("SAFE CALL FAILED: \nScenario: \(scenario.debugDescription)\n\(r)")
        }
    }
    
    return result
}
