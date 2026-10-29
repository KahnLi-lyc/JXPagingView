// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "JXPagingView",
    platforms: [.iOS(.v8)],
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
    swiftLanguageVersions: [.v5]
)
