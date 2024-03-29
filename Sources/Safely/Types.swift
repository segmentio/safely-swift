//
//  Types.swift
//  
//
//  Created by Brandon Sneed on 1/30/23.
//

import Foundation

/// Describes the scenario and who implemented it.
/// We want to codify that we're doing this for a specific reason,
/// why we're doing it, and who decided it was necessary.
/// 
/// Example:
/// ```
/// struct Scenarios {
///     static let nullPListSettings = SafeScenario(
///         description: "Guard against NULL potentially being set to UserDefaults",
///         implementor: "@bsneed"
///     )
///     static let externalSDKCrash = SafeScenario(
///         description: "Prevent unhandled exceptions from 3rd party SDKs",
///         implementor: "@bsneed"
///     )
/// }
/// ```
public struct SafeScenario {
    public let description: String
    public let implementor: String
    public init(description: String, implementor: String) {
        self.description = description
        self.implementor = implementor
    }
}

/// An empty context structure.  Useful where no context is necessary for a safe call.
public struct NoContext {
    public init() {}
}

extension SafeScenario: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(description) implemented by \(implementor)"
    }
}

/// An Error representing a system signal.
public class SignalError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        return "SignalError: \(signal)"
    }
    
    // The signal that was raised.
    public let signal: Int32
    public init(signal: Int32) {
        self.signal = signal
    }
}

/// An Error represending an ObjC exception (on supported platforms).  It provides as much 
/// information about the exception as possible, including the call stack.
public class ExceptionError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        return """
        \(NSUnderlyingErrorKey): \(exception),
        \(NSLocalizedDescriptionKey): \(exception.reason ?? "unknown"),
        Call Stack: \n   \(exception.callStackSymbols.joined(separator: "\n   "))
        """
    }
    
    /// The ObjC exception that was raised.
    public let exception: NSException
    public init(exception: NSException) {
        self.exception = exception
    }
}

public class AssertionError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        return "AssertionError: \(message) - Occurred at line \(line) in \(file)"
    }
    
    public let file: String
    public let line: UInt
    public let message: String
    public let prefix: String
    
    public init(prefix: String, message: String, file: String, line: UInt) {
        self.prefix = prefix
        self.message = message
        self.file = file
        self.line = line
    }
}

extension NSException: @unchecked Sendable {}
