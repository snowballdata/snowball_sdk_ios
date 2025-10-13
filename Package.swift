// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnowBallEngine",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SnowBallEngine",
            targets: ["SnowBallEngineTarget"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk.git", exact: "4.36.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.1.0"),
    ],
    targets: [
        .binaryTarget(
            name: "SnowBallEngineFramework",
            path: "SnowBallEngine.xcframework"
        ),
        .target(
            name: "SnowBallEngineTarget",
            dependencies: [
                "SnowBallEngineFramework",
                .product(name: "Adjust", package: "ios_sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ],
            path: "Sources/SnowBallEngineTarget"
        ),
    ]
)
