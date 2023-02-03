
#if os(Linux) || os(Windows)

import Foundation

internal func SACatchException(_ tryBlock: () -> Void) -> NSException? {
    tryBlock()
    return nil
}

public class NSException {
    public let reason: String? = nil
    public let callStackSymbols: [String] = [""]
}

extension NSNull: @unchecked Sendable {}

#endif