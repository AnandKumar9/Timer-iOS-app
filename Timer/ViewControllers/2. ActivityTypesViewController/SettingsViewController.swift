import UIKit

final class SettingsViewController: UIViewController {
    private final class OptionButton: UIControl {
        private let titleLabel = UILabel()
        private let accessoryImageView = UIImageView()
        private let swatchView = UIView()

        var title: String? {
            get { titleLabel.text }
            set { titleLabel.text = newValue }
        }

        var titleFont: UIFont? {
            get { titleLabel.font }
            set { titleLabel.font = newValue }
        }

        var swatchColor: UIColor? {
            didSet {
                swatchView.backgroundColor = swatchColor
                swatchView.isHidden = swatchColor == nil
            }
        }

        override var isSelected: Bool {
            didSet {
                accessoryImageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                accessoryImageView.tintColor = isSelected ? AppTheme.accent : AppTheme.metadataText
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            configure()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }

        func applyTheme() {
            backgroundColor = AppTheme.cardBackground
            layer.borderColor = (isSelected ? AppTheme.accent : AppTheme.separator).cgColor
            titleLabel.textColor = AppTheme.primaryText
            accessoryImageView.tintColor = isSelected ? AppTheme.accent : AppTheme.metadataText
        }

        private func configure() {
            layer.cornerRadius = 8
            layer.borderWidth = 1

            titleLabel.numberOfLines = 1
            titleLabel.adjustsFontForContentSizeCategory = true

            accessoryImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            accessoryImageView.setContentHuggingPriority(.required, for: .horizontal)

            swatchView.isHidden = true
            swatchView.layer.cornerRadius = 8
            swatchView.layer.masksToBounds = true
            swatchView.translatesAutoresizingMaskIntoConstraints = false

            let stackView = UIStackView(arrangedSubviews: [swatchView, titleLabel, accessoryImageView])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 12
            stackView.isUserInteractionEnabled = false
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                swatchView.widthAnchor.constraint(equalToConstant: 18),
                swatchView.heightAnchor.constraint(equalToConstant: 18),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
            ])

            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
            isSelected = false
            applyTheme()
        }
    }

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let versionLabel = UILabel()
    private lazy var lightModeButton = makeAppearanceButton(
        systemImageName: "sun.max",
        accessibilityLabel: "Light Mode",
        action: UIAction { [weak self] _ in
            self?.appearanceButtonTapped(style: .light)
        }
    )
    private lazy var darkModeButton = makeAppearanceButton(
        systemImageName: "moon",
        accessibilityLabel: "Dark Mode",
        action: UIAction { [weak self] _ in
            self?.appearanceButtonTapped(style: .dark)
        }
    )
    private var fontButtons: [AppFont: OptionButton] = [:]
    private var accentButtons: [AppAccentColor: OptionButton] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureLayout()
        configureSections()
        registerForThemeChanges()
        updateSelections()
        applyTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNavigation() {
        title = "Theme"
        navigationItem.rightBarButtonItem = nil
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.text = appVersionText()
        versionLabel.textAlignment = .right
        versionLabel.setContentHuggingPriority(.required, for: .horizontal)
        versionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func configureSections() {
        contentStackView.addArrangedSubview(makeAppearanceSection())
        contentStackView.addArrangedSubview(makeSection(title: "Font", contentView: makeFontOptionsView()))
        contentStackView.addArrangedSubview(makeSection(title: "Accent Color", contentView: makeAccentOptionsView()))
        contentStackView.addArrangedSubview(versionLabel)
    }

    private func makeFontOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        AppFont.allCases.forEach { font in
            let button = OptionButton()
            button.title = font.displayName
            button.titleFont = AppTheme.font(font, ofSize: 17, weight: .semibold)
            button.addAction(
                UIAction { _ in
                    AppTheme.selectedFont = font
                },
                for: .touchUpInside
            )
            fontButtons[font] = button
            stackView.addArrangedSubview(button)
        }

        return stackView
    }

    private func makeAccentOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        AppAccentColor.allCases.forEach { accentColor in
            let button = OptionButton()
            button.title = accentColor.displayName
            button.titleFont = AppTheme.roundedFont(ofSize: 17, weight: .semibold)
            button.swatchColor = accentColor.previewColor
            button.addAction(
                UIAction { _ in
                    AppTheme.selectedAccentColor = accentColor
                },
                for: .touchUpInside
            )
            accentButtons[accentColor] = button
            stackView.addArrangedSubview(button)
        }

        return stackView
    }

    private func makeOptionsStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }

    private func makeSection(title: String, contentView: UIView) -> UIView {
        let titleLabel = makeSectionTitleLabel(title)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentView])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }

    private func makeAppearanceSection() -> UIView {
        let titleLabel = makeSectionTitleLabel("Appearance")
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let buttonsStackView = UIStackView(arrangedSubviews: [lightModeButton, darkModeButton])
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .center
        buttonsStackView.spacing = 8
        buttonsStackView.setContentHuggingPriority(.required, for: .horizontal)
        buttonsStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerStackView = UIStackView(arrangedSubviews: [titleLabel, spacerView, buttonsStackView])
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 12

        return headerStackView
    }

    private func makeSectionTitleLabel(_ title: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = AppTheme.metadataText
        titleLabel.textAlignment = .natural
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        return titleLabel
    }

    private func makeAppearanceButton(
        systemImageName: String,
        accessibilityLabel: String,
        action: UIAction
    ) -> UIButton {
        let button = UIButton(type: .custom)
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        let image = UIImage(
            systemName: systemImageName,
            withConfiguration: symbolConfiguration
        )?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.setImage(image, for: .highlighted)
        button.addAction(action, for: .touchUpInside)
        button.accessibilityLabel = accessibilityLabel
        button.adjustsImageWhenHighlighted = false
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])

        return button
    }

    private func registerForThemeChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: AppTheme.didChangeNotification,
            object: nil
        )
    }

    @objc private func themeDidChange() {
        updateSelections()
        applyTheme()
    }

    private func appearanceButtonTapped(style: UIUserInterfaceStyle) {
        AppAppearanceController.setAppearance(style)
    }

    private func updateSelections() {
        let selectedAppearance = selectedAppearanceStyle()
        lightModeButton.isSelected = selectedAppearance == .light
        darkModeButton.isSelected = selectedAppearance == .dark

        fontButtons.forEach { font, button in
            button.isSelected = font == AppTheme.selectedFont
        }

        accentButtons.forEach { accentColor, button in
            button.isSelected = accentColor == AppTheme.selectedAccentColor
        }
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        scrollView.backgroundColor = AppTheme.screenBackground
        versionLabel.font = AppTheme.roundedFont(ofSize: 11, weight: .regular)
        versionLabel.textColor = AppTheme.metadataText
        navigationController?.navigationBar.tintColor = AppTheme.accent
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        applyAppearanceButtonTheme(lightModeButton)
        applyAppearanceButtonTheme(darkModeButton)

        contentStackView.arrangedSubviews.forEach { sectionView in
            guard let sectionStackView = sectionView as? UIStackView,
                  let titleLabel = sectionStackView.arrangedSubviews.first as? UILabel else {
                return
            }

            titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = AppTheme.metadataText
        }

        fontButtons.forEach { font, button in
            button.titleFont = AppTheme.font(font, ofSize: 17, weight: .semibold)
            button.applyTheme()
        }

        accentButtons.forEach { _, button in
            button.titleFont = AppTheme.roundedFont(ofSize: 17, weight: .semibold)
            button.applyTheme()
        }
    }

    private func applyAppearanceButtonTheme(_ button: UIButton) {
        let isDarkMode = selectedAppearanceStyle() == .dark
        button.backgroundColor = .clear
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.tintColor = isDarkMode ? .white : .black
        button.layer.borderWidth = button.isSelected ? 1.5 : 0
        button.layer.borderColor = AppTheme.accent.cgColor
    }

    private func navigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.screenBackground
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .semibold)
        ]
        return appearance
    }

    private func selectedAppearanceStyle() -> UIUserInterfaceStyle {
        let savedStyle = AppAppearanceController.savedUserInterfaceStyle
        return savedStyle == .unspecified ? traitCollection.userInterfaceStyle : savedStyle
    }

    private func appVersionText() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let components = version.split(separator: ".").map(String.init)
        let normalizedComponents = Array((components + ["0", "0", "0"]).prefix(3))
        return "v\(normalizedComponents.joined(separator: "."))"
    }
}
