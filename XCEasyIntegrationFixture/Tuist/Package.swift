// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Alamofire": .framework
    ]
)
#endif

let package = Package(
    name: "XCEasyIntegrationFixture",
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            .upToNextMajor(from: "5.10.0")
        )
    ]
)