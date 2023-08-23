
#if os(Linux) || os(Windows)

import Foundation

public class NSException {
    public let reason: String? = nil
    public let callStackSymbols: [String] = [""]
}

extension NSNull: @unchecked Sendable {}

#endif