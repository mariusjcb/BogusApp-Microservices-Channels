// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "BogusApp-Microservices-Channels",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(name: "BogusApp-Common-Models", url: "https://github.com/mariusjcb/BogusApp-Common-Models.git", .branch("master")),
        .package(name: "BogusApp-Common-MockDataProvider", url: "https://github.com/mariusjcb/BogusApp-Common-MockDataProvider.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Channels",
            dependencies: [
                .product(name: "BogusApp-Common-Models", package: "BogusApp-Common-Models"),
                .product(name: "BogusApp-Common-MockDataProvider", package: "BogusApp-Common-MockDataProvider"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
            ],
            path: "Sources/App",
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run Channels", dependencies: [.target(name: "Channels")], path: "Sources/Run"),
        .testTarget(
            name: "Channles Tests",
            dependencies: [
                .target(name: "Channels"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            path: "Tests/AppTests"
        )
    ]
)
