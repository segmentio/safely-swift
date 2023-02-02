//
//  SafeDefinitions.swift
//  
//
//  Created by Brandon Sneed on 1/30/23.
//

import Foundation
@testable import Safely

struct Scenarios {
    static let nullPListSettings = SafeScenario(
        description: "Guard against NULL potentially being set to tvOS UserDefaults",
        implementor: "@bsneed"
    )
    static let dummyThrowingFunction = SafeScenario(
        description: "Guard against a swift function throwing",
        implementor: "@bsneed"
    )
}
