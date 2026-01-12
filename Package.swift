// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GiftyTask",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GiftyTask",
            targets: ["GiftyTask"]),
    ],
    dependencies: [
        // 将来的にFirebase SDKなどを追加する場合はここに記載
        // .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "GiftyTask",
            dependencies: [],
            path: ".",
            sources: [
                "App",
                "Models",
                "Views",
                "Utilities",
                "ContentView.swift"
            ],
            resources: [
                // 将来的にアセットを追加する場合はここに記載
            ]
        ),
    ]
)

