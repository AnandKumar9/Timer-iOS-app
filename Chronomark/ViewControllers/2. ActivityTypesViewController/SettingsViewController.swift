import UIKit

enum AppSettings {
    private static let alertWhenTimersRestoredKey = "alertWhenTimersRestored"

    static var alertWhenTimersRestored: Bool {
        get {
            UserDefaults.standard.bool(forKey: alertWhenTimersRestoredKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: alertWhenTimersRestoredKey)
        }
    }
}

final class SettingsViewController: UIViewController {
    private final class SettingsRow: UIView {
        private let iconImageView = UIImageView()
        private let titleLabel = UILabel()
        private let subtitleLabel = UILabel()
        private let trailingView: UIView

        init(
            systemImageName: String,
            title: String,
            subtitle: String? = nil,
            trailingView: UIView
        ) {
            self.trailingView = trailingView
            super.init(frame: .zero)
            titleLabel.text = title
            subtitleLabel.text = subtitle
            iconImageView.image = UIImage(systemName: systemImageName)
            iconImageView.contentMode = .scaleAspectFit
            configure()
        }

        required init?(coder: NSCoder) {
            fatalError("Use init(systemImageName:title:subtitle:trailingView:) instead.")
        }

        func applyTheme() {
            backgroundColor = AppTheme.cardBackground
            layer.borderColor = AppTheme.separator.cgColor
            iconImageView.tintColor = AppTheme.metadataText
            titleLabel.font = AppTheme.roundedFont(ofSize: 16, weight: .semibold)
            titleLabel.textColor = AppTheme.primaryText
            subtitleLabel.font = AppTheme.roundedFont(ofSize: 12, weight: .regular)
            subtitleLabel.textColor = AppTheme.metadataText

            if let label = trailingView as? UILabel {
                label.font = AppTheme.roundedFont(ofSize: 15, weight: .semibold)
                label.textColor = AppTheme.accent
            } else if let control = trailingView as? UISwitch {
                control.onTintColor = AppTheme.accent
            }
        }

        private func configure() {
            layer.cornerRadius = 8
            layer.borderWidth = 1
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)

            iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            iconImageView.setContentHuggingPriority(.required, for: .horizontal)
            iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            iconImageView.translatesAutoresizingMaskIntoConstraints = false

            titleLabel.numberOfLines = 1
            titleLabel.adjustsFontForContentSizeCategory = true

            subtitleLabel.numberOfLines = 2
            subtitleLabel.adjustsFontForContentSizeCategory = true
            subtitleLabel.isHidden = subtitleLabel.text?.isEmpty ?? true

            let labelsStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            labelsStackView.axis = .vertical
            labelsStackView.spacing = 3

            trailingView.setContentHuggingPriority(.required, for: .horizontal)
            trailingView.setContentCompressionResistancePriority(.required, for: .horizontal)

            let rowStackView = UIStackView(arrangedSubviews: [iconImageView, labelsStackView, trailingView])
            rowStackView.axis = .horizontal
            rowStackView.alignment = .center
            rowStackView.spacing = 12
            rowStackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(rowStackView)

            NSLayoutConstraint.activate([
                rowStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                rowStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                rowStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                rowStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 22),
                iconImageView.heightAnchor.constraint(equalToConstant: 22),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 58)
            ])

            applyTheme()
        }
    }

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
    private let disclaimerLabel = UILabel()
    private let precisionDisclaimerLabel = UILabel()
    private let versionLabel = UILabel()
    private lazy var systemModeButton = makeAppearanceButton(
        systemImageName: "circle.lefthalf.filled",
        accessibilityLabel: "System Appearance",
        action: UIAction { [weak self] _ in
            self?.appearanceButtonTapped(mode: .system)
        }
    )
    private lazy var lightModeButton = makeAppearanceButton(
        systemImageName: "sun.max",
        accessibilityLabel: "Light Mode",
        action: UIAction { [weak self] _ in
            self?.appearanceButtonTapped(mode: .light)
        }
    )
    private lazy var darkModeButton = makeAppearanceButton(
        systemImageName: "moon",
        accessibilityLabel: "Dark Mode",
        action: UIAction { [weak self] _ in
            self?.appearanceButtonTapped(mode: .dark)
        }
    )
    private var fontButtons: [AppFont: OptionButton] = [:]
    private var accentButtons: [AppAccentColor: OptionButton] = [:]
    private var settingsRows: [SettingsRow] = []
    private var sectionTitleLabels: [UILabel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureLayout()
        configureSections()
        registerForThemeChanges()
        registerForUserInterfaceStyleChanges()
        updateSelections()
        applyTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNavigation() {
        title = "Settings"
        navigationItem.rightBarButtonItem = nil
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        disclaimerLabel.text = "When you launch the app, we try to restore timers you did not stop in your previous session."
        
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.textAlignment = .natural
        precisionDisclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        precisionDisclaimerLabel.text = "Chronomark is not intended for precision-critical timing, but it is just fine for typical timer use."
        precisionDisclaimerLabel.numberOfLines = 0
        precisionDisclaimerLabel.textAlignment = .natural
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
        contentStackView.addArrangedSubview(makeTimerBehaviorSection())
        contentStackView.addArrangedSubview(makeFooterSection())
    }

    private func makeTimerBehaviorSection() -> UIView {
        let titleLabel = makeSectionTitleLabel("Timer Behavior")
        let stackView = UIStackView(arrangedSubviews: [titleLabel, disclaimerLabel, makeTimerBehaviorOptionsView()])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }

    private func makeTimerBehaviorOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        let alertWhenRestoredSwitch = UISwitch()
        alertWhenRestoredSwitch.isOn = AppSettings.alertWhenTimersRestored
        alertWhenRestoredSwitch.addAction(
            UIAction { action in
                guard let toggle = action.sender as? UISwitch else {
                    return
                }

                AppSettings.alertWhenTimersRestored = toggle.isOn
            },
            for: .valueChanged
        )
        stackView.addArrangedSubview(
            makeSettingsRow(
                systemImageName: "timer",
                title: "Alert when restored",
                subtitle: "Show a confirmation alert every time old timers are restored.",
                trailingView: alertWhenRestoredSwitch
            )
        )

        let checkpointSwitch = UISwitch()
        checkpointSwitch.isOn = true
        stackView.addArrangedSubview(
            makeSettingsRow(
                systemImageName: "arrow.triangle.2.circlepath",
                title: "Background Checkpoints",
                subtitle: "Keep a local timer checkpoint while the app is open.",
                trailingView: checkpointSwitch
            )
        )

        let restoreWindowLabel = UILabel()
        restoreWindowLabel.text = "8 hr"
        stackView.addArrangedSubview(
            makeSettingsRow(
                systemImageName: "clock.arrow.circlepath",
                title: "Restore Window",
                subtitle: "Maximum age for restoring cached timers.",
                trailingView: restoreWindowLabel
            )
        )

        return stackView
    }

    private func makeSettingsRow(
        systemImageName: String,
        title: String,
        subtitle: String?,
        trailingView: UIView
    ) -> SettingsRow {
        let row = SettingsRow(
            systemImageName: systemImageName,
            title: title,
            subtitle: subtitle,
            trailingView: trailingView
        )
        settingsRows.append(row)
        return row
    }

    private func makeFooterSection() -> UIView {
        let stackView = UIStackView(arrangedSubviews: [precisionDisclaimerLabel, versionLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
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

        let buttonsStackView = UIStackView(arrangedSubviews: [lightModeButton, darkModeButton, systemModeButton])
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
        sectionTitleLabels.append(titleLabel)
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

    private func registerForUserInterfaceStyleChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.updateSelections()
            viewController.applyTheme()
        }
    }

    @objc private func themeDidChange() {
        updateSelections()
        applyTheme()
    }

    private func appearanceButtonTapped(mode: AppAppearanceMode) {
        AppAppearanceController.setAppearanceMode(mode)
    }

    private func updateSelections() {
        let selectedAppearanceMode = AppAppearanceController.savedAppearanceMode
        systemModeButton.isSelected = selectedAppearanceMode == .system
        lightModeButton.isSelected = selectedAppearanceMode == .light
        darkModeButton.isSelected = selectedAppearanceMode == .dark

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
        disclaimerLabel.font = AppTheme.roundedFont(ofSize: 12, weight: .regular)
        disclaimerLabel.textColor = AppTheme.metadataText
        precisionDisclaimerLabel.font = AppTheme.roundedFont(ofSize: 12, weight: .regular)
        precisionDisclaimerLabel.textColor = AppTheme.metadataText
        versionLabel.font = AppTheme.roundedFont(ofSize: 11, weight: .regular)
        versionLabel.textColor = AppTheme.metadataText
        navigationController?.navigationBar.tintColor = AppTheme.accent
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        applyAppearanceButtonTheme(systemModeButton, mode: .system)
        applyAppearanceButtonTheme(lightModeButton, mode: .light)
        applyAppearanceButtonTheme(darkModeButton, mode: .dark)

        sectionTitleLabels.forEach { titleLabel in
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

        settingsRows.forEach { $0.applyTheme() }
    }

    private func applyAppearanceButtonTheme(_ button: UIButton, mode: AppAppearanceMode) {
        let resolvedStyle = selectedAppearanceStyle()
        let selectedMode = AppAppearanceController.savedAppearanceMode
        let showsResolvedSystemMode = selectedMode == .system && mode.userInterfaceStyle == resolvedStyle
        let isProminent = button.isSelected || showsResolvedSystemMode

        button.backgroundColor = isProminent ? AppTheme.accent.withAlphaComponent(button.isSelected ? 0.18 : 0.12) : .clear
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.tintColor = button.isSelected || showsResolvedSystemMode ? AppTheme.accent : AppTheme.metadataText
        button.layer.borderWidth = button.isSelected ? 1.5 : (showsResolvedSystemMode ? 1 : 0)
        button.layer.borderColor = (button.isSelected ? AppTheme.accent : AppTheme.accent.withAlphaComponent(0.55)).cgColor
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
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let components = version.split(separator: ".").map(String.init)
        let normalizedComponents = Array((components + ["0", "0", "0"]).prefix(3))
        return "Version \(normalizedComponents.joined(separator: ".")) (\(buildNumber))"
    }
}
