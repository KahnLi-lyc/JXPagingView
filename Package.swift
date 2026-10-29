// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "JXPagingView",
    platforms: [.iOS(.v16)],
    products: [.library(name: "JXPagingView", targets: ["JXPagingView"])],
    targets: [
        .target(
            name: "JXPagingView",
            path: "Sources",
            sources: ["JXPagingView"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(name: "JXPagingViewTests", dependencies: ["JXPagingView"]),
    ],
    swiftLanguageModes: [.v6]
)
