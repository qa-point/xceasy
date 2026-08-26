import XCTest
@testable import XCEasy

final class LocalizationManagerTests: XCTestCase {
    func testPackageResourceBundleContainsLocalizationCatalog() {
        XCTAssertNotNil(
            Bundle.module.path(
                forResource: "Localizable",
                ofType: "strings",
                inDirectory: "en.lproj"
            )
        )
    }

    func testEnglishAndRussianCatalogsRenderTheSameKey() {
        let manager = LocalizationManager.shared

        manager.setLocalization(for: "en")
        XCTAssertEqual(
            manager.string(forKey: "tap_on_element_title", arguments: ["Banner"]),
            "Tap on element [Banner]"
        )

        manager.setLocalization(for: "ru")
        XCTAssertEqual(
            manager.string(forKey: "tap_on_element_title", arguments: ["Banner"]),
            "Нажать на элемент [Banner]"
        )
    }

    func testUnknownLanguageFallsBackToEnglish() {
        let manager = LocalizationManager.shared
        manager.setLocalization(for: "unsupported")

        XCTAssertEqual(
            manager.string(forKey: "tap_on_element_title", arguments: ["Banner"]),
            "Tap on element [Banner]"
        )
    }

    func testCatalogIsIsolatedBetweenParallelThreads() {
        let expectation = expectation(description: "both localized values")
        expectation.expectedFulfillmentCount = 2
        let lock = NSLock()
        var values: Set<String> = []

        for language in ["en", "ru"] {
            Thread.detachNewThread {
                let manager = LocalizationManager.shared
                manager.setLocalization(for: language)
                let value = manager.string(forKey: "tap_on_element_title", arguments: ["Banner"])
                lock.lock()
                values.insert(value)
                lock.unlock()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(values, ["Tap on element [Banner]", "Нажать на элемент [Banner]"])
    }

    func testNewExecutionThreadLoadsConfiguredCatalogOnFirstRead() {
        XCEasyConfig.localization = .en
        let expectation = expectation(description: "default catalog loaded")
        let lock = NSLock()
        var value: String?

        Thread.detachNewThread {
            let localized = LocalizationManager.shared.string(
                forKey: "component_collection_select_first"
            )
            lock.lock()
            value = localized
            lock.unlock()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
        lock.lock()
        let observedValue = value
        lock.unlock()
        XCTAssertEqual(observedValue, "Create locator for the first component")
    }
}
