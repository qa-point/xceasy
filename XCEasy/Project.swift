import ProjectDescription

// MARK: - Project

let project = Project(
    name: "XCEasy",
    organizationName: "qa-point",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [
        .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .exact("603.0.2"))
    ],
    targets: [
        .target(
            name: "XCEasy",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.qa-point.XCEasy",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: .resources([.glob(pattern: "Resources/**")]),
            dependencies: [
                .xctest,
                .external(name: "Alamofire"),
                .macro(name: "XCEasyMacroPlugin")
            ]
        ),
        .target(
            name: "XCEasyMacroPlugin",
            destinations: .macOS,
            product: .macro,
            bundleId: "com.qa-point.XCEasyMacroPlugin",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: ["../XCEasyMacroPlugin/Sources/**"],
            dependencies: [
                .package(product: "SwiftCompilerPlugin", type: .macro),
                .package(product: "SwiftDiagnostics"),
                .package(product: "SwiftSyntax"),
                .package(product: "SwiftSyntaxBuilder"),
                .package(product: "SwiftSyntaxMacros")
            ]
        ),
        .target(
            name: "XCEasyTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.qa-point.XCEasyTests",
            deploymentTargets: .iOS("15.0"),
            sources: ["Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "XCEasy"),
                .xctest
            ]
        ),
        .target(
            name: "XCEasyUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.qa-point.XCEasyUITests",
            deploymentTargets: .iOS("15.0"),
            sources: ["UITests/**"],
            resources: [],
            dependencies: [
                .target(name: "XCEasy"),
                .xctest
            ]
        ),
    ]
)
