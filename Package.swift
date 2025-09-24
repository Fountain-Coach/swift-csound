// swift-tools-version: 5.9

import PackageDescription

let packageName = "FountainCoachSwiftCsound"

var targets: [Target] = [
    .target(
        name: "SPManager",
        dependencies: [],
        swiftSettings: [
            .unsafeFlags(["-enable-actor-data-race-checks"], .when(configuration: .debug))
        ]
    ),
    .testTarget(
        name: "SPManagerTests",
        dependencies: ["SPManager"]
    )
]

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
let csoundDependencies: [Target.Dependency] = ["SPManager", "Csound"]
targets.append(
    .binaryTarget(
        name: "Csound",
        path: "Artifacts/Csound.xcframework"
    )
)
#else
let csoundDependencies: [Target.Dependency] = ["SPManager"]
#endif

targets.append(
    .target(
        name: "SPCsoundBackend",
        dependencies: csoundDependencies,
        swiftSettings: [
            .unsafeFlags(["-enable-actor-data-race-checks"], .when(configuration: .debug))
        ]
    )
)

let package = Package(
    name: packageName,
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "SPManager", targets: ["SPManager"]),
        .library(name: "SPCsoundBackend", targets: ["SPCsoundBackend"])
    ],
    targets: targets
)
