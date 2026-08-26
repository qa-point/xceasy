import XCEasy

class XCEasyIntegrationFixtureTestCase: XCEasyTestCase, ScreenProvider {

    override func configuration() {
        XCEasyConfig.apply(
            findTimeout: 2,
            assertionTimeout: 2,
            localization: .ru,
            printLogToConsole: false,
            uiQueryEvidenceLevel: .basic
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

        // actions before test
    }

    override func afterTest() {
        super.afterTest()

        // actions after test
    }
}
