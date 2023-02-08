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

/// Useful where no context is necessary for a safe call.
public struct NoContext {
    public init() {}
}

extension SafeScenario: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(description) implemented by \(implementor)"
    }
}

public class SignalError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        return ""
    }
    
    public let signal: Int32
    public init(signal: Int32) {
        self.signal = signal
    }
}

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
    
    public let exception: NSException
    public init(exception: NSException) {
        self.exception = exception
    }
}

extension NSException: @unchecked Sendable {}
