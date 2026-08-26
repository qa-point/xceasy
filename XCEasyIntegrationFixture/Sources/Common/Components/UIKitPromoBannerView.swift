import UIKit

final class UIKitPromoBannerView: UIView {
    var onClose: (() -> Void)?
    private let generation: Int

    /// Creates a reusable banner generation for removal/replacement UI tests.
    ///
    /// - Parameter generation: Visible generation number while identifiers remain stable.
    init(generation: Int = 1) {
        self.generation = generation
        super.init(frame: .zero)
        setupUI()
    }

    /// Creates the default banner when UIKit initializes it with a frame.
    ///
    /// - Parameter frame: Initial banner frame supplied by UIKit.
    override init(frame: CGRect) {
        generation = 1
        super.init(frame: frame)
        setupUI()
    }

    /// Restores the default banner from an interface archive.
    ///
    /// - Parameter coder: Decoder supplied by UIKit.
    required init?(coder: NSCoder) {
        generation = 1
        super.init(coder: coder)
        setupUI()
    }

    /// Builds banner labels, close control, constraints, and accessibility identifiers.
    private func setupUI() {
        accessibilityIdentifier = "UIKit.PromoBanner"
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = "Special offer \(generation)"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.accessibilityIdentifier = "UIKit.PromoBanner.Title"

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Reusable UIKit banner component"
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.accessibilityIdentifier = "UIKit.PromoBanner.Subtitle"

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.accessibilityLabel = "Close promotion banner"
        closeButton.accessibilityIdentifier = "UIKit.PromoBanner.CloseButton"
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [labels, closeButton])
        content.axis = .horizontal
        content.alignment = .top
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    /// Notifies the owning screen that the banner should leave the hierarchy.
    @objc private func close() {
        onClose?()
    }
}
