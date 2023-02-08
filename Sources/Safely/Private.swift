//
//  File.swift
//  
//
//  Created by Brandon Sneed on 2/4/23.
//

import Foundation
#if !os(Linux) && !os(Windows)
import SafelyInternal
#endif

internal func updateSignalHandler(_ onSignals: ((Error) -> Void)?) {
    if onSignals == nil {
        // clear the signal handlers
        signal(SIGILL, nil)
        signal(SIGABRT, nil)
        signal(SIGTRAP, nil)
    } else {
        signal(SIGILL, _signalHandler)
        signal(SIGABRT, _signalHandler)
        signal(SIGTRAP, _signalHandler)
    }
}

internal func _signalHandler(_ signal: Int32) -> Void {
    print("signal handler")
    guard let onSignals = SafelyOptions.onSignals else { return }
    let e = SignalError(signal: signal)
    onSignals(e)
}

#if !os(Linux) && !os(Windows)
internal func updateUncaughtExceptionHandler(_ onUncaughtException: ((Error) -> Void)?) {
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
#endif
