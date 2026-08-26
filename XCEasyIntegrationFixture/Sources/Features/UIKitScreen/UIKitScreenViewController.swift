import UIKit

// MARK: - UIKitScreenViewController

/// UIKit view controller demonstrating all reusable components.
///
/// This screen displays all reusable components (input, switch, checkbox,
/// radio buttons, list items) with a loading indicator for testing purposes.
class UIKitScreenViewController: UIViewController {

    // MARK: - Properties

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Components

    private let inputField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter text"
        field.borderStyle = .roundedRect
        field.accessibilityIdentifier = "uiKitInputComponent"
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        return field
    }()

    private let switchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let switchLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable feature"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let switchControl: UISwitch = {
        let sw = UISwitch()
        sw.accessibilityIdentifier = "uiKitSwitchComponent"
        return sw
    }()

    private let checkboxContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let checkboxLabel: UILabel = {
        let label = UILabel()
        label.text = "Accept terms"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkboxButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        button.accessibilityIdentifier = "uiKitCheckboxComponent"
        button.tintColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let radioButton1: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "circle.fill"), for: .selected)
        button.accessibilityIdentifier = "uiKitRadioButton1"
        button.tintColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let radioButton2: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "circle.fill"), for: .selected)
        button.accessibilityIdentifier = "uiKitRadioButton2"
        button.tintColor = .blue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let listItem1: UIView = createListItem(icon: "star.fill", text: "Item 1", identifier: "uiKitListItem1")
    private let listItem2: UIView = createListItem(icon: "heart.fill", text: "Item 2", identifier: "uiKitListItem2")
    private let listItem3: UIView = createListItem(icon: "bookmark.fill", text: "Item 3", identifier: "uiKitListItem3")

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.accessibilityIdentifier = "uiKitLoadingView"
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let loadContentButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Load Content"
        config.baseBackgroundColor = .blue
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = "uiKitLoadContentButton"
        return button
    }()

    private var promoBanner = UIKitPromoBannerView()
    private var promoBannerGeneration = 1

    private let showPromoBannerButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Show new promo banner"
        let button = UIButton(configuration: configuration)
        button.accessibilityIdentifier = "UIKit.PromoBanner.ShowButton"
        return button
    }()

    private var contentStack: UIStackView?

    // MARK: - State

    private var isCheckboxSelected: Bool = false
    private var selectedRadioButton: Int = 0
    private var isLoading: Bool = false

    // MARK: - Lifecycle

    /// Builds the deterministic UIKit fixture after the view hierarchy loads.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup

    /// Creates the complete fixture hierarchy with stable accessibility identifiers.
    private func setupUI() {
        view.backgroundColor = .white
        title = "UIKit Screen"

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Setup switch container with horizontal stack
        let switchStack = UIStackView(arrangedSubviews: [switchLabel, switchControl])
        switchStack.axis = .horizontal
        switchStack.spacing = 8
        switchStack.translatesAutoresizingMaskIntoConstraints = false
        switchStack.distribution = .fill

        NSLayoutConstraint.activate([
            switchLabel.centerYAnchor.constraint(equalTo: switchControl.centerYAnchor)
        ])

        // Setup checkbox container
        checkboxContainer.addSubview(checkboxLabel)
        checkboxContainer.addSubview(checkboxButton)
        NSLayoutConstraint.activate([
            checkboxLabel.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor),
            checkboxLabel.centerYAnchor.constraint(equalTo: checkboxContainer.centerYAnchor),
            checkboxButton.leadingAnchor.constraint(equalTo: checkboxLabel.trailingAnchor, constant: 8),
            checkboxButton.trailingAnchor.constraint(equalTo: checkboxContainer.trailingAnchor),
            checkboxButton.centerYAnchor.constraint(equalTo: checkboxContainer.centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 44),
            checkboxButton.heightAnchor.constraint(equalToConstant: 44),
            checkboxContainer.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Setup radio buttons container
        let radioContainer = UIView()
        radioContainer.translatesAutoresizingMaskIntoConstraints = false

        let radioLabel1 = UILabel()
        radioLabel1.text = "Option 1"
        radioLabel1.translatesAutoresizingMaskIntoConstraints = false

        let radioLabel2 = UILabel()
        radioLabel2.text = "Option 2"
        radioLabel2.translatesAutoresizingMaskIntoConstraints = false

        radioContainer.addSubview(radioLabel1)
        radioContainer.addSubview(radioButton1)
        radioContainer.addSubview(radioLabel2)
        radioContainer.addSubview(radioButton2)

        NSLayoutConstraint.activate([
            radioLabel1.topAnchor.constraint(equalTo: radioContainer.topAnchor),
            radioLabel1.leadingAnchor.constraint(equalTo: radioContainer.leadingAnchor),
            radioLabel1.centerYAnchor.constraint(equalTo: radioButton1.centerYAnchor),
            radioButton1.leadingAnchor.constraint(equalTo: radioLabel1.trailingAnchor, constant: 8),
            radioButton1.widthAnchor.constraint(equalToConstant: 44),
            radioButton1.heightAnchor.constraint(equalToConstant: 44),
            radioButton1.trailingAnchor.constraint(equalTo: radioContainer.trailingAnchor),

            radioLabel2.topAnchor.constraint(equalTo: radioButton1.bottomAnchor, constant: 8),
            radioLabel2.leadingAnchor.constraint(equalTo: radioContainer.leadingAnchor),
            radioLabel2.centerYAnchor.constraint(equalTo: radioButton2.centerYAnchor),
            radioButton2.leadingAnchor.constraint(equalTo: radioLabel2.trailingAnchor, constant: 8),
            radioButton2.widthAnchor.constraint(equalToConstant: 44),
            radioButton2.heightAnchor.constraint(equalToConstant: 44),
            radioButton2.trailingAnchor.constraint(equalTo: radioContainer.trailingAnchor),
            radioButton2.bottomAnchor.constraint(equalTo: radioContainer.bottomAnchor)
        ])

        // Add screen title label
        let screenTitleLabel = UILabel()
        screenTitleLabel.text = "UIKit Screen"
        screenTitleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        screenTitleLabel.textAlignment = .center
        screenTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        screenTitleLabel.accessibilityIdentifier = "UIKitscreenTitleLabel"
        contentView.addSubview(screenTitleLabel)

        let stackView = UIStackView(arrangedSubviews: [
            promoBanner,
            showPromoBannerButton,
            createSectionLabel(text: "Input"),
            inputField,
            createSectionLabel(text: "Switch"),
            switchStack,
            createSectionLabel(text: "Checkbox"),
            checkboxContainer,
            createSectionLabel(text: "Radio Buttons"),
            radioContainer,
            createSectionLabel(text: "List Items"),
            listItem1,
            listItem2,
            listItem3,
            createSectionLabel(text: "Actions"),
            loadContentButton,
            loadingIndicator
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        contentStack = stackView

        NSLayoutConstraint.activate([
            screenTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            screenTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            screenTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            screenTitleLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: screenTitleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    /// Connects fixture controls to deterministic local state transitions.
    private func setupActions() {
        configurePromoBannerCloseAction()
        showPromoBannerButton.addTarget(self, action: #selector(showNewPromoBanner), for: .touchUpInside)
        checkboxButton.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)

        radioButton1.addTarget(self, action: #selector(selectRadio1), for: .touchUpInside)
        radioButton2.addTarget(self, action: #selector(selectRadio2), for: .touchUpInside)

        loadContentButton.addTarget(self, action: #selector(loadContent), for: .touchUpInside)
    }

    // MARK: - Actions

    /// Toggles the checkbox state exposed to XCUI.
    @objc private func toggleCheckbox() {
        isCheckboxSelected.toggle()
        checkboxButton.isSelected = isCheckboxSelected
    }

    /// Replaces a removed promo banner with a new generation using the same identifiers.
    @objc private func showNewPromoBanner() {
        guard promoBanner.superview == nil, let contentStack else { return }
        promoBannerGeneration += 1
        promoBanner = UIKitPromoBannerView(generation: promoBannerGeneration)
        configurePromoBannerCloseAction()
        contentStack.insertArrangedSubview(promoBanner, at: 0)
    }

    /// Configures the current banner to remove itself from the UIKit hierarchy.
    private func configurePromoBannerCloseAction() {
        promoBanner.onClose = { [weak self] in
            self?.promoBanner.removeFromSuperview()
        }
    }

    /// Selects the first radio option and clears the second.
    @objc private func selectRadio1() {
        selectedRadioButton = 1
        radioButton1.isSelected = true
        radioButton2.isSelected = false
    }

    /// Selects the second radio option and clears the first.
    @objc private func selectRadio2() {
        selectedRadioButton = 2
        radioButton1.isSelected = false
        radioButton2.isSelected = true
    }

    /// Runs the fixture loading transition used by visibility assertions.
    @objc private func loadContent() {
        isLoading = true
        loadingIndicator.startAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isLoading = false
            self?.loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Helper Methods

    /// Creates a consistently styled label for a fixture section.
    ///
    /// - Parameter text: Visible section title.
    /// - Returns: Configured UIKit label.
    private func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }

    /// Creates a list-item fixture with stable identifiers for both text and icon.
    ///
    /// - Parameters:
    ///   - icon: SF Symbols image name.
    ///   - text: Visible item title.
    ///   - identifier: Base accessibility identifier for XCUI lookup.
    /// - Returns: Configured list-item container.
    private static func createListItem(icon: String, text: String, identifier: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView(image: UIImage(systemName: icon))
        iconImageView.tintColor = .blue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.accessibilityIdentifier = identifier + "Icon"

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.accessibilityIdentifier = identifier

        let stackView = UIStackView(arrangedSubviews: [iconImageView, textLabel])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stackView)
        container.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            container.heightAnchor.constraint(equalToConstant: 44)
        ])

        return container
    }
}
