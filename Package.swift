// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "XCEasy",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(name: "XCEasy", targets: ["XCEasy", "XCEasyBootstrap"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            exact: "5.10.2"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "603.0.2"
        )
    ],
    targets: [
        .target(
            name: "XCEasy",
            dependencies: ["Alamofire", "XCEasyMacroPlugin"],
            path: "XCEasy",
            exclude: [
                "Sources/TestStructure/XCEasyTestObserver/XCEasyTestObserverBootstrap.m"
            ],
            sources: ["Sources"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "XCEasyBootstrap",
            dependencies: ["XCEasy"],
            path: "XCEasy/Sources/TestStructure/XCEasyTestObserver",
            sources: ["XCEasyTestObserverBootstrap.m"],
            publicHeadersPath: ".",
            linkerSettings: [.linkedFramework("XCTest")]
        ),
        .macro(
            name: "XCEasyMacroPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            path: "XCEasyMacroPlugin/Sources"
        ),
        .testTarget(
            name: "XCEasyTests",
            dependencies: ["XCEasy"],
            path: "XCEasy/Tests"
        )
    ]
)
