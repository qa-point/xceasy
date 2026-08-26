import XCEasy

final class PromoBannerIntegrationTests: XCEasyIntegrationFixtureTestCase {
    func testSwiftUIBannerUsesFreshLocatorAfterRemoval() {
        feature("SwiftUI")
        story("Reusable promo banner")

        tabBar.select(tab: .swiftUI)
        let banner = swiftUIScreen.promoBanner

        assertTrue(
            expression: banner.waitForDisplayed(timeout: 2),
            label: "promo banner became displayed"
        )
        assertTrue(
            expression: banner.closeButton.waitForHittable(timeout: 2),
            label: "promo banner close button became hittable"
        )
        assertTrue(
            expression: banner.closeButton.waitForEnabled(timeout: 2),
            label: "promo banner close button became enabled"
        )
        banner.assertContentExists()
        banner.element.assertIsDisplayed().assertIsHittable()
        banner.dismiss()
        banner.element.assertDoesNotExist(timeout: 1)
        banner.element.assertIsNotDisplayed(timeout: 1).assertIsNotHittable(timeout: 1)
        banner.closeButton.assertDoesNotExist(timeout: 1)
    }

    func testUIKitBannerUsesFreshLocatorAfterRemoval() {
        feature("UIKit")
        story("Reusable promo banner")

        tabBar.select(tab: .uiKit)
        let banner = uiKitScreen.promoBanner

        banner.assertContentExists()
        banner.element.assertIsDisplayed().assertIsHittable()
        banner.dismiss()
        banner.element.assertDoesNotExist(timeout: 1)
        banner.element.assertIsNotDisplayed(timeout: 1).assertIsNotHittable(timeout: 1)
        banner.closeButton.assertDoesNotExist(timeout: 1)
    }

    func testSwiftUIStoredPOMResolvesReplacementWithSameIdentifiers() {
        feature("SwiftUI")
        story("Fresh component replacement")

        tabBar.select(tab: .swiftUI)
        let banner = swiftUIScreen.promoBanner
        banner.assertGeneration(1)
        banner.dismiss()

        swiftUIScreen.showPromoBannerButton.tap(policy: .displayed)

        banner.assertContentExists()
        banner.assertGeneration(2)
    }

    func testUIKitStoredPOMResolvesReplacementWithSameIdentifiers() {
        feature("UIKit")
        story("Fresh component replacement")

        tabBar.select(tab: .uiKit)
        let banner = uiKitScreen.promoBanner
        banner.assertGeneration(1)
        banner.dismiss()

        uiKitScreen.showPromoBannerButton.tap()

        banner.assertContentExists()
        banner.assertGeneration(2)
    }
}
