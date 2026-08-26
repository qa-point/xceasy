import XCEasy

struct SwiftUIListItemComponentPOM: XCEasyIndexedComponent {
    static var collection: XCEasyUIElement {
        find(identifier: "SwiftUi.ListItem", desc: "SwiftUI list items")
    }

    private let position: XCEasyComponentPosition
    let componentName: String

    init(position: XCEasyComponentPosition, componentName: String?) {
        self.position = position
        self.componentName = componentName ?? Self.defaultComponentName(for: position)
    }

    var element: XCEasyUIElement {
        Self.collection.element(at: position, desc: componentName)
    }

    var icon: XCEasyUIElement {
        element.child(
            identifier: "SwiftUi.ListItem.Icon",
            desc: "\(componentName) icon"
        )
    }

    var title: XCEasyUIElement {
        element.child(
            identifier: "SwiftUi.ListItem.Title",
            desc: "\(componentName) title"
        )
    }

}
