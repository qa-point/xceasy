// swift-tools-version: 5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "XCEasyMacroPluginTests",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "603.0.2")
    ],
    targets: [
        .macro(
            name: "XCEasyMacroPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "XCEasyMacroPluginTests",
            dependencies: [
                "XCEasyMacroPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Tests"
        )
    ]
)
