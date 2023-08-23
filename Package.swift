// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


#if os(Linux) || os(Windows)
let targets: [Target] = [
    .target(
        name: "Safely"
    )
]
#else
let targets: [Target] = [
    .target(
        name: "SafelyInternal"
    ),
    .target(
        name: "Safely",
        dependencies: ["SafelyInternal"]
    ),
]
#endif


let package = Package(
    name: "Safely",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("11.0"),
        .watchOS("7.1")
    ],
    products: [
        .library(
            name: "Safely",
            targets: ["Safely"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: targets + [
        .testTarget(
            name: "SafelyTests",
            dependencies: ["Safely"]
        )
    ]
)
