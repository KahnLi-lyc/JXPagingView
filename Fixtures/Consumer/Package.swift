// swift-tools-version: 6.0
import PackageDescription

// Each host selects its own language mode; the local dependency keeps Swift 6.
let package = Package(
    name: "JXPagingViewConsumerCompatibility",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "ConsumerSwift5", targets: ["ConsumerSwift5"]),
        .library(name: "ConsumerSwift6", targets: ["ConsumerSwift6"]),
    ],
    dependencies: [.package(name: "JXPagingView", path: "../..")],
    targets: [
        .target(
            name: "ConsumerSwift5",
            dependencies: [.product(name: "JXPagingView", package: "JXPagingView")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "ConsumerSwift6",
            dependencies: [.product(name: "JXPagingView", package: "JXPagingView")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
