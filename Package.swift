// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LC3VM",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "LC3VM", targets: ["LC3VM"]),
        .library(name: "LC3VMCore", targets: ["LC3VMCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "LC3VM",
            dependencies: [
                .target(name: "LC3VMCore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "LC3VMCore"
        ),
        .testTarget(
            name: "lc3vmTests",
            dependencies: ["LC3VMCore"]
        ),
    ]
)
