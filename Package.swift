// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TestSDK",
            targets: ["TestSDK", "TestSDKWrapper"]
        ),
    ],
    dependencies: [
        // Firebase dependencies - 必须声明,因为 XCFramework 依赖这些库
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "12.1.0"
        )
    ],
    targets: [
        // Binary target - 你的预编译 XCFramework
        .binaryTarget(
            name: "TestSDK",
            path: "TestSDK.xcframework"
        ),

        // Wrapper target - 声明依赖关系
        .target(
            name: "TestSDKWrapper",
            dependencies: [
                "TestSDK",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "Sources/TestSDKWrapper"
        )
    ]
)
