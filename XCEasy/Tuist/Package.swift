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
    name: "XCEasy",
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            exact: "5.10.2"
        )
    ]
)
