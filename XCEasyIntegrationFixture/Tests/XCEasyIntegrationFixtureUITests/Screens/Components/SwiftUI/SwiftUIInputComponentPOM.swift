import XCEasy

// MARK: - Elements

struct SwiftUIInputComponentPOM {
    private let identifier: String
    private let index: Int

    init (identifier: String = "SwiftUi.InputComponent", index: Int = 0) {
        self.identifier = identifier
        self.index = index
    }

    private var element: XCEasyUIElement {
        find(
            identifier: identifier,
            index: index,
            desc: "'\(index + 1)' Input element"
        )
    }
}

// MARK: - Actions

extension SwiftUIInputComponentPOM {
    @discardableResult
    func fill(text: String) -> Self {
        step("Fill input \(index + 1)") {
            element
                .typeText(text)
        }
        return self
    }
}

// MARK: - Asserts

extension SwiftUIInputComponentPOM {
    @discardableResult
    func assertExists() -> Self {
        step("Check '\(index + 1)' Input exists") {
            element
                .assertExists()
        }
        return self
    }

    @discardableResult
    func assertValue(text: String) -> Self {
        step("Check '\(index + 1)' Input value") {
            element
                .assertValue(text: text)
        }
        return self
    }
}
