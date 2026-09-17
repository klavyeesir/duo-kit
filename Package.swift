// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "duo-kit",
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DuoLint",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/DuoLint"
        )
    ]
)