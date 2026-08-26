import XCEasy
import XCTest

class XCEasyTests: XCEasyTestCase {

    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.apple.mobilesafari",
            findTimeout: 2,
            assertionTimeout: 2,
            localization: .en,
            printLogToConsole: true
        )

        XCEasyAllureConfig.apply(linkPatterns: [
            "issue": "https://myjira.com/{}",
            "tms": "https://mytms.com/{}"
        ])

        LaunchArgumentsManager.add("test_argument")

        super.configuration()
    }

    override func beforeTest() {
        super.beforeTest()

        // сделать что-то перед началом теста
    }

    override func afterTest() {
        super.afterTest()

        // сделать что-то после теста
    }

    func test_Success() {
        displayName("Success Test")
        XCEasy.description("Test for Test Descripotion")
        epic("EPIC")
        feature("FEATURE")
        story("STORY")
        suite("SUITE")
        owner("Owner1")
        severity(.blocker)
        tag("iOS", "Smoke")
        issue("QQ-228")
        tms("TR-222")
        id("12334412")

        step("1 step") {

            let element = find(identifier: "SidebarButton")

            step("2 step") {

                step("2.1 step") {

                    element.assertExists()

                }

            }
        }
    }

    func test_Failed() {
        displayName("Failed Test")
        XCEasy.description("Test for Test Descripotion")
        epic("EPIC")
        feature("FEATURE")
        story("STORY")
        suite("SUITE")
        owner("Owner1")
        severity(.blocker)
        tag("iOS", "Smoke")
        issue("QQ-228")
        tms("TR-222")
        id("12334412")


        step("1 step") {

            let element = find(identifier: "failedID")

            step("2 step") {

                step("2.1 step") {

                    assertTrue(
                        expression: element.isExists(),
                        label: "Element with identifier 'failedID' exists"
                    )

                }

            }

        }
    }

}
