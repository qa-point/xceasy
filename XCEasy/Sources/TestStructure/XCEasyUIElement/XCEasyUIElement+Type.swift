import XCTest

// MARK: - XCEasyUIElement Types

public extension XCEasyUIElement {

    // MARK: - ElementType

    /// Enumeration representing UI element types.
    enum ElementType {
        case any, other, application, group, window, sheet, drawer, alert, dialog, button, radioButton, radioGroup, checkBox, disclosureTriangle, popUpButton, comboBox, menuButton, toolbarButton, popover, keyboard, key, navigationBar, tabBar, tabGroup, toolbar, statusBar, table, tableRow, tableColumn, outline, outlineRow, browser, collectionView, slider, pageIndicator, progressIndicator, activityIndicator, segmentedControl, picker, pickerWheel, `switch`, toggle, link, image, icon, searchField, scrollView, scrollBar, staticText, textField, secureTextField, datePicker, textView, menu, menuItem, menuBar, menuBarItem, map, webView, incrementArrow, decrementArrow, timeline, ratingIndicator, valueIndicator, splitGroup, splitter, relevanceIndicator, colorWell, helpTag, matte, dockItem, ruler, rulerMarker, grid, levelIndicator, cell, layoutArea, layoutItem, handle, stepper, tab, touchBar, statusItem

        var properties: ElementTypeModel {
            switch self {
            case .any:
                return ElementTypeModel(type: .any, description: "Any")
            case .other:
                return ElementTypeModel(type: .other, description: "Other")
            case .application:
                return ElementTypeModel(type: .application, description: "Application")
            case .group:
                return ElementTypeModel(type: .group, description: "Group")
            case .window:
                return ElementTypeModel(type: .window, description: "Window")
            case .sheet:
                return ElementTypeModel(type: .sheet, description: "Sheet")
            case .drawer:
                return ElementTypeModel(type: .drawer, description: "Drawer")
            case .alert:
                return ElementTypeModel(type: .alert, description: "Alert")
            case .dialog:
                return ElementTypeModel(type: .dialog, description: "Dialog")
            case .button:
                return ElementTypeModel(type: .button, description: "Button")
            case .radioButton:
                return ElementTypeModel(type: .radioButton, description: "Radio Button")
            case .radioGroup:
                return ElementTypeModel(type: .radioGroup, description: "Radio Group")
            case .checkBox:
                return ElementTypeModel(type: .checkBox, description: "Check Box")
            case .disclosureTriangle:
                return ElementTypeModel(type: .disclosureTriangle, description: "Disclosure Triangle")
            case .popUpButton:
                return ElementTypeModel(type: .popUpButton, description: "Pop Up Button")
            case .comboBox:
                return ElementTypeModel(type: .comboBox, description: "Combo Box")
            case .menuButton:
                return ElementTypeModel(type: .menuButton, description: "Menu Button")
            case .toolbarButton:
                return ElementTypeModel(type: .toolbarButton, description: "Toolbar Button")
            case .popover:
                return ElementTypeModel(type: .popover, description: "Popover")
            case .keyboard:
                return ElementTypeModel(type: .keyboard, description: "Keyboard")
            case .key:
                return ElementTypeModel(type: .key, description: "Key")
            case .navigationBar:
                return ElementTypeModel(type: .navigationBar, description: "Navigation Bar")
            case .tabBar:
                return ElementTypeModel(type: .tabBar, description: "Tab Bar")
            case .tabGroup:
                return ElementTypeModel(type: .tabGroup, description: "Tab Group")
            case .toolbar:
                return ElementTypeModel(type: .toolbar, description: "Toolbar")
            case .statusBar:
                return ElementTypeModel(type: .statusBar, description: "Status Bar")
            case .table:
                return ElementTypeModel(type: .table, description: "Table")
            case .tableRow:
                return ElementTypeModel(type: .tableRow, description: "Table Row")
            case .tableColumn:
                return ElementTypeModel(type: .tableColumn, description: "Table Column")
            case .outline:
                return ElementTypeModel(type: .outline, description: "Outline")
            case .outlineRow:
                return ElementTypeModel(type: .outlineRow, description: "Outline Row")
            case .browser:
                return ElementTypeModel(type: .browser, description: "Browser")
            case .collectionView:
                return ElementTypeModel(type: .collectionView, description: "Collection View")
            case .slider:
                return ElementTypeModel(type: .slider, description: "Slider")
            case .pageIndicator:
                return ElementTypeModel(type: .pageIndicator, description: "Page Indicator")
            case .progressIndicator:
                return ElementTypeModel(type: .progressIndicator, description: "Progress Indicator")
            case .activityIndicator:
                return ElementTypeModel(type: .activityIndicator, description: "Activity Indicator")
            case .segmentedControl:
                return ElementTypeModel(type: .segmentedControl, description: "Segmented Control")
            case .picker:
                return ElementTypeModel(type: .picker, description: "Picker")
            case .pickerWheel:
                return ElementTypeModel(type: .pickerWheel, description: "Picker Wheel")
            case .switch:
                return ElementTypeModel(type: .switch, description: "Switch")
            case .toggle:
                return ElementTypeModel(type: .toggle, description: "Toggle")
            case .link:
                return ElementTypeModel(type: .link, description: "Link")
            case .image:
                return ElementTypeModel(type: .image, description: "Image")
            case .icon:
                return ElementTypeModel(type: .icon, description: "Icon")
            case .searchField:
                return ElementTypeModel(type: .searchField, description: "Search Field")
            case .scrollView:
                return ElementTypeModel(type: .scrollView, description: "Scroll View")
            case .scrollBar:
                return ElementTypeModel(type: .scrollBar, description: "Scroll Bar")
            case .staticText:
                return ElementTypeModel(type: .staticText, description: "Static Text")
            case .textField:
                return ElementTypeModel(type: .textField, description: "Text Field")
            case .secureTextField:
                return ElementTypeModel(type: .secureTextField, description: "Secure Text Field")
            case .datePicker:
                return ElementTypeModel(type: .datePicker, description: "Date Picker")
            case .textView:
                return ElementTypeModel(type: .textView, description: "Text View")
            case .menu:
                return ElementTypeModel(type: .menu, description: "Menu")
            case .menuItem:
                return ElementTypeModel(type: .menuItem, description: "Menu Item")
            case .menuBar:
                return ElementTypeModel(type: .menuBar, description: "Menu Bar")
            case .menuBarItem:
                return ElementTypeModel(type: .menuBarItem, description: "Menu Bar Item")
            case .map:
                return ElementTypeModel(type: .map, description: "Map")
            case .webView:
                return ElementTypeModel(type: .webView, description: "Web View")
            case .incrementArrow:
                return ElementTypeModel(type: .incrementArrow, description: "Increment Arrow")
            case .decrementArrow:
                return ElementTypeModel(type: .decrementArrow, description: "Decrement Arrow")
            case .timeline:
                return ElementTypeModel(type: .timeline, description: "Timeline")
            case .ratingIndicator:
                return ElementTypeModel(type: .ratingIndicator, description: "Rating Indicator")
            case .valueIndicator:
                return ElementTypeModel(type: .valueIndicator, description: "Value Indicator")
            case .splitGroup:
                return ElementTypeModel(type: .splitGroup, description: "Split Group")
            case .splitter:
                return ElementTypeModel(type: .splitter, description: "Splitter")
            case .relevanceIndicator:
                return ElementTypeModel(type: .relevanceIndicator, description: "Relevance Indicator")
            case .colorWell:
                return ElementTypeModel(type: .colorWell, description: "Color Well")
            case .helpTag:
                return ElementTypeModel(type: .helpTag, description: "Help Tag")
            case .matte:
                return ElementTypeModel(type: .matte, description: "Matte")
            case .dockItem:
                return ElementTypeModel(type: .dockItem, description: "Dock Item")
            case .ruler:
                return ElementTypeModel(type: .ruler, description: "Ruler")
            case .rulerMarker:
                return ElementTypeModel(type: .rulerMarker, description: "Ruler Marker")
            case .grid:
                return ElementTypeModel(type: .grid, description: "Grid")
            case .levelIndicator:
                return ElementTypeModel(type: .levelIndicator, description: "Level Indicator")
            case .cell:
                return ElementTypeModel(type: .cell, description: "Cell")
            case .layoutArea:
                return ElementTypeModel(type: .layoutArea, description: "Layout Area")
            case .layoutItem:
                return ElementTypeModel(type: .layoutItem, description: "Layout Item")
            case .handle:
                return ElementTypeModel(type: .handle, description: "Handle")
            case .stepper:
                return ElementTypeModel(type: .stepper, description: "Stepper")
            case .tab:
                return ElementTypeModel(type: .tab, description: "Tab")
            case .touchBar:
                return ElementTypeModel(type: .touchBar, description: "Touch Bar")
            case .statusItem:
                return ElementTypeModel(type: .statusItem, description: "Status Item")
            }
        }
    }

    // MARK: - ElementTypeModel

    /// Model representing an element type with its description.
    struct ElementTypeModel {
        let type: XCUIElement.ElementType
        let description: String
    }

    // MARK: - SwipeDirection

    /// Enumeration representing swipe directions.
    enum SwipeDirection {
        case up, down, left, right
    }
}
