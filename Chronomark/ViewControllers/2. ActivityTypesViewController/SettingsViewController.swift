import UIKit

enum AppSettings {
    static let durationDisplayDidChangeNotification = Notification.Name("AppSettings.durationDisplayDidChangeNotification")
    static let activityTypeDisplayOrderDidChangeNotification = Notification.Name("AppSettings.activityTypeDisplayOrderDidChangeNotification")

    enum ActivityTypeDisplayOrder: String, CaseIterable {
        case name
        case latestActivity

        var displayName: String {
            switch self {
            case .name:
                return "Sort by Name"
            case .latestActivity:
                return "Sort by Latest Activity"
            }
        }
    }

    private static let alertWhenTimersRestoredKey = "alertWhenTimersRestored"
    private static let restoreWindowHoursKey = "restoreWindowHours"
    private static let showDurationSecondsKey = "showDurationSeconds"
    private static let activityTypeDisplayOrderKey = "activityTypeDisplayOrder"
    private static let defaultActivityTypeDisplayOrder: ActivityTypeDisplayOrder = .name
    private static let defaultRestoreWindowHours = 8
    static let restoreWindowHourOptions = [4, 8, 24]

    static var alertWhenTimersRestored: Bool {
        get {
            UserDefaults.standard.bool(forKey: alertWhenTimersRestoredKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: alertWhenTimersRestoredKey)
        }
    }

    static var restoreWindowHours: Int {
        get {
            let savedHours = UserDefaults.standard.integer(forKey: restoreWindowHoursKey)
            guard savedHours > 0 else {
                return defaultRestoreWindowHours
            }

            return restoreWindowHourOptions.min { lhs, rhs in
                abs(lhs - savedHours) < abs(rhs - savedHours)
            } ?? defaultRestoreWindowHours
        }
        set {
            guard restoreWindowHourOptions.contains(newValue) else {
                UserDefaults.standard.set(defaultRestoreWindowHours, forKey: restoreWindowHoursKey)
                return
            }

            UserDefaults.standard.set(newValue, forKey: restoreWindowHoursKey)
        }
    }

    static var restoreWindowInterval: TimeInterval {
        TimeInterval(restoreWindowHours * 60 * 60)
    }

    static var showDurationSeconds: Bool {
        get {
            UserDefaults.standard.bool(forKey: showDurationSecondsKey)
        }
        set {
            guard newValue != showDurationSeconds else {
                return
            }

            UserDefaults.standard.set(newValue, forKey: showDurationSecondsKey)
            NotificationCenter.default.post(name: durationDisplayDidChangeNotification, object: nil)
        }
    }

    static var activityTypeDisplayOrder: ActivityTypeDisplayOrder {
        get {
            guard
                let rawValue = UserDefaults.standard.string(forKey: activityTypeDisplayOrderKey),
                let displayOrder = ActivityTypeDisplayOrder(rawValue: rawValue)
            else {
                return defaultActivityTypeDisplayOrder
            }

            return displayOrder
        }
        set {
            guard newValue != activityTypeDisplayOrder else {
                return
            }

            UserDefaults.standard.set(newValue.rawValue, forKey: activityTypeDisplayOrderKey)
            NotificationCenter.default.post(name: activityTypeDisplayOrderDidChangeNotification, object: nil)
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
            } else if let button = trailingView as? UIButton {
                button.tintColor = AppTheme.accent
                button.configuration?.baseForegroundColor = AppTheme.accent
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

    private final class AccentSwatchButton: UIControl {
        private let fillView = UIView()
        private let titleLabel = UILabel()
        private let accentColor: AppAccentColor

        override var isSelected: Bool {
            didSet {
                updateSelectionAppearance()
            }
        }

        init(accentColor: AppAccentColor) {
            self.accentColor = accentColor
            super.init(frame: .zero)
            configure()
        }

        required init?(coder: NSCoder) {
            fatalError("Use init(accentColor:) instead.")
        }

        func applyTheme() {
            fillView.backgroundColor = accentColor.previewColor
            updateSelectionAppearance()
            titleLabel.font = AppTheme.roundedFont(ofSize: 14, weight: .semibold)
            titleLabel.textColor = readableTextColor(for: accentColor.previewColor)
        }

        private func configure() {
            layer.cornerRadius = 8
            layer.borderWidth = 1
            backgroundColor = .clear
            accessibilityLabel = "\(accentColor.displayName) Accent Color"
            accessibilityTraits.insert(.button)
            translatesAutoresizingMaskIntoConstraints = false

            fillView.layer.cornerRadius = 6
            fillView.layer.masksToBounds = true
            fillView.translatesAutoresizingMaskIntoConstraints = false
            fillView.isUserInteractionEnabled = false

            titleLabel.text = accentColor.displayName
            titleLabel.textAlignment = .center
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.75
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.isUserInteractionEnabled = false

            addSubview(fillView)
            addSubview(titleLabel)

            NSLayoutConstraint.activate([
                heightAnchor.constraint(equalToConstant: 44),
                fillView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
                fillView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
                fillView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
                fillView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
                titleLabel.leadingAnchor.constraint(equalTo: fillView.leadingAnchor, constant: 6),
                titleLabel.trailingAnchor.constraint(equalTo: fillView.trailingAnchor, constant: -6),
                titleLabel.centerYAnchor.constraint(equalTo: fillView.centerYAnchor)
            ])

            applyTheme()
        }

        private func updateSelectionAppearance() {
            layer.borderWidth = isSelected ? 2.5 : 1
            layer.borderColor = (isSelected ? AppTheme.primaryText : AppTheme.separator).cgColor
            accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }

        private func readableTextColor(for color: UIColor) -> UIColor {
            let resolvedColor = color.resolvedColor(with: traitCollection)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return .white
            }

            let luminance = (0.299 * red) + (0.587 * green) + (0.114 * blue)
            return luminance > 0.62 ? .black : .white
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
    private var accentButtons: [AppAccentColor: AccentSwatchButton] = [:]
    private var displayOrderButtons: [AppSettings.ActivityTypeDisplayOrder: OptionButton] = [:]
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
        disclaimerLabel.text = "Timers left running in previous app session get restored."
        
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.textAlignment = .natural
        precisionDisclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        precisionDisclaimerLabel.text = "Chronomark is designed for everyday stopwatch tasks, not precision-critical measurement."
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
        contentStackView.addArrangedSubview(makeSection(title: "Display Order", contentView: makeDisplayOrderOptionsView()))
        contentStackView.addArrangedSubview(makeTimeDisplaySection())
        contentStackView.addArrangedSubview(makeTimerBehaviorSection())
        contentStackView.addArrangedSubview(makeFooterSection())
    }

    private func makeTimerBehaviorSection() -> UIView {
        let titleLabel = makeSectionTitleLabel("Timer Restoration")
        let stackView = UIStackView(arrangedSubviews: [titleLabel, disclaimerLabel, makeTimerBehaviorOptionsView()])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }

    private func makeTimerBehaviorOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        let restoreWindowButton = makeRestoreWindowButton()
        stackView.addArrangedSubview(
            makeSettingsRow(
                systemImageName: "clock.arrow.circlepath",
                title: "Restore Window",
                subtitle: "Oldest cached timers to restore.",
                trailingView: restoreWindowButton
            )
        )

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
                systemImageName: "exclamationmark.bubble",
                title: "Alert When Restored",
                subtitle: "Show a confirmation alert when old timers are restored.",
                trailingView: alertWhenRestoredSwitch
            )
        )

        return stackView
    }

    private func makeTimeDisplaySection() -> UIView {
        makeSection(title: "Time Display", contentView: makeTimeDisplayOptionsView())
    }

    private func makeTimeDisplayOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        let showDurationSecondsSwitch = UISwitch()
        showDurationSecondsSwitch.isOn = AppSettings.showDurationSeconds
        showDurationSecondsSwitch.addAction(
            UIAction { action in
                guard let toggle = action.sender as? UISwitch else {
                    return
                }

                AppSettings.showDurationSeconds = toggle.isOn
            },
            for: .valueChanged
        )
        stackView.addArrangedSubview(
            makeSettingsRow(
                systemImageName: "stopwatch",
                title: "Show Duration Seconds",
                subtitle: "Include seconds in completed activity durations.",
                trailingView: showDurationSecondsSwitch
            )
        )

        return stackView
    }

    private func makeRestoreWindowButton() -> UIButton {
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        button.configuration = restoreWindowButtonConfiguration(hours: AppSettings.restoreWindowHours)
        button.menu = restoreWindowMenu(button: button)
        return button
    }

    private func restoreWindowMenu(button: UIButton) -> UIMenu {
        let actions = AppSettings.restoreWindowHourOptions.map { hours in
            UIAction(
                title: restoreWindowTitle(hours: hours),
                state: hours == AppSettings.restoreWindowHours ? .on : .off
            ) { [weak button, weak self] _ in
                guard let self else {
                    return
                }

                AppSettings.restoreWindowHours = hours
                button?.configuration = self.restoreWindowButtonConfiguration(hours: hours)
                if let button {
                    button.menu = self.restoreWindowMenu(button: button)
                }
            }
        }

        return UIMenu(children: actions)
    }

    private func restoreWindowButtonConfiguration(hours: Int) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.title = restoreWindowTitle(hours: hours)
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.baseForegroundColor = AppTheme.accent
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 0)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppTheme.roundedFont(ofSize: 15, weight: .semibold)
            return outgoing
        }
        return configuration
    }

    private func restoreWindowTitle(hours: Int) -> String {
        hours == 24 ? "1 day" : "\(hours) hr"
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
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 6

        AppAccentColor.allCases.forEach { accentColor in
            let button = AccentSwatchButton(accentColor: accentColor)
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

    private func makeDisplayOrderOptionsView() -> UIView {
        let stackView = makeOptionsStackView()

        AppSettings.ActivityTypeDisplayOrder.allCases.forEach { displayOrder in
            let button = OptionButton()
            button.title = displayOrder.displayName
            button.titleFont = AppTheme.roundedFont(ofSize: 17, weight: .semibold)
            button.addAction(
                UIAction { [weak self] _ in
                    AppSettings.activityTypeDisplayOrder = displayOrder
                    self?.updateSelections()
                    self?.applyTheme()
                },
                for: .touchUpInside
            )
            displayOrderButtons[displayOrder] = button
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

        displayOrderButtons.forEach { displayOrder, button in
            button.isSelected = displayOrder == AppSettings.activityTypeDisplayOrder
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

        accentButtons.forEach { _, button in button.applyTheme() }

        displayOrderButtons.forEach { _, button in
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
