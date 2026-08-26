import ProjectDescription

// MARK: - Project

let project = Project(
    name: "XCEasyIntegrationFixture",
    organizationName: "qa-point",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    targets: [
        .target(
            name: "XCEasyIntegrationFixture",
            destinations: .iOS,
            product: .app,
            bundleId: "com.qa-point.xceasy-integration-fixture",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ]
                ]
            ),
            sources: ["Sources/**"],
            resources: .resources([.glob(pattern: "Resources/**")]),
            dependencies: []
        ),
        .target(
            name: "XCEasyIntegrationFixtureUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.qa-point.xceasy-integration-fixture.uikit",
            deploymentTargets: .iOS("15.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "XCEasyIntegrationFixture"),
                .project(target: "XCEasy", path: "../XCEasy")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "XCEasyIntegrationFixture",
            shared: true,
            buildAction: .buildAction(
                targets: ["XCEasyIntegrationFixture"]
            ),
            testAction: .targets(
                ["XCEasyIntegrationFixtureUITests"],
                arguments: .arguments(
                    environmentVariables: [
                        "XC_EASY_BUNDLE_ID": "com.qa-point.xceasy-integration-fixture"
                    ]
                )
            ),
            runAction: .runAction(
                arguments: .arguments(
                    environmentVariables: [
                        "XC_EASY_BUNDLE_ID": "com.qa-point.xceasy-integration-fixture"
                    ]
                )
            )
        )
    ]
)
