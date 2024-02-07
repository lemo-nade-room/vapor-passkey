// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-passkey",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Passkey",
            targets: ["Passkey"])
    ],
    dependencies: [
        // DocC
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // Passkey
        .package(url: "https://github.com/swift-server/webauthn-swift.git", from: "1.0.0-alpha"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Passkey",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "WebAuthn", package: "webauthn-swift"),
            ]
        ),
        .testTarget(
            name: "PasskeyTests",
            dependencies: ["Passkey"]),
    ]
)
