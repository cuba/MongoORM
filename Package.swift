// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MongoORM",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MongoORM",
            targets: ["MongoORM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "4.0.0"),
        .package(url: "https://github.com/cuba/MapCodableKit.git", from: "1.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MongoORM",
            dependencies: ["MongoKitten", "MapCodableKit"],
            path: "Sources"
        ),
        .testTarget(
            name: "MongoORMTests",
            dependencies: ["MongoORM"],
            path: "Tests"
        ),
    ]
)
