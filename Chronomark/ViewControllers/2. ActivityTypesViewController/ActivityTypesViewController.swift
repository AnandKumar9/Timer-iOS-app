import UIKit
import SwiftData

final class ActivityTypesViewController: UIViewController {
    private struct ActivityTypeRow {
        let activityType: ActivityType
        let name: String
        let latestActivity: Activity?
        let latestActivityStartTime: Date?
        let timerState: ActivityTimerState
        let tagPreviewTexts: [String]
    }

    private final class ActivityTypeCell: UITableViewCell {
        static let reuseIdentifier = "ActivityTypeCell"

        private final class PillLabel: UILabel {
            private let contentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

            override var intrinsicContentSize: CGSize {
                let size = super.intrinsicContentSize
                return CGSize(
                    width: size.width + contentInsets.left + contentInsets.right,
                    height: size.height + contentInsets.top + contentInsets.bottom
                )
            }

            override func drawText(in rect: CGRect) {
                super.drawText(in: rect.inset(by: contentInsets))
            }
        }

        var onStartTapped: (() -> Void)?
        var onTimerStatusTapped: (() -> Void)?

        private let nameLabel = UILabel()
        private let latestActivityLabel = UILabel()
        private let tagPreviewContainerView = UIView()
        private let tagPreviewStackView = UIStackView()
        private let actionView = ActivityTimerActionView()
        private let maximumVisibleTagCount = 4

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        override func prepareForReuse() {
            super.prepareForReuse()

            onStartTapped = nil
            onTimerStatusTapped = nil
            actionView.prepareForReuse()
        }

        func configure(with row: ActivityTypeRow) {
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground
            nameLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
            nameLabel.textColor = AppTheme.primaryText
            latestActivityLabel.font = AppTheme.roundedFont(ofSize: 14, weight: .regular)
            latestActivityLabel.textColor = AppTheme.metadataText
            nameLabel.text = row.name
            configureTagPreviews(row.tagPreviewTexts)
            actionView.onRecordTapped = { [weak self] in
                self?.onStartTapped?()
            }
            actionView.onTimerStatusTapped = { [weak self] in
                self?.onTimerStatusTapped?()
            }
            actionView.configure(timerState: row.timerState)

            if
                let latestActivity = row.latestActivity,
                let latestActivityStartTime = row.latestActivityStartTime {
                latestActivityLabel.text = makeLatestActivityText(
                    activity: latestActivity,
                    startTime: latestActivityStartTime
                )
            } else {
                latestActivityLabel.text = "No activity recorded"
            }
        }

        private func configureCell() {
            backgroundColor = AppTheme.screenBackground
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground
            contentView.backgroundColor = AppTheme.screenBackground

            nameLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
            nameLabel.textColor = AppTheme.primaryText
            nameLabel.numberOfLines = 1

            latestActivityLabel.font = AppTheme.roundedFont(ofSize: 14, weight: .regular)
            latestActivityLabel.textColor = AppTheme.metadataText
            latestActivityLabel.numberOfLines = 1

            tagPreviewStackView.axis = .horizontal
            tagPreviewStackView.alignment = .center
            tagPreviewStackView.spacing = 6
            tagPreviewStackView.translatesAutoresizingMaskIntoConstraints = false

            tagPreviewContainerView.addSubview(tagPreviewStackView)

            let activityMetadataStackView = UIStackView(arrangedSubviews: [latestActivityLabel, tagPreviewContainerView])
            activityMetadataStackView.axis = .vertical
            activityMetadataStackView.alignment = .fill
            activityMetadataStackView.spacing = 5

            let labelStackView = UIStackView(arrangedSubviews: [nameLabel, activityMetadataStackView])
            labelStackView.axis = .vertical
            labelStackView.alignment = .fill
            labelStackView.spacing = 4
            labelStackView.translatesAutoresizingMaskIntoConstraints = false

            actionView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(labelStackView)
            contentView.addSubview(actionView)

            NSLayoutConstraint.activate([
                labelStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                labelStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                labelStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
                labelStackView.trailingAnchor.constraint(equalTo: actionView.leadingAnchor, constant: -16),
                tagPreviewStackView.leadingAnchor.constraint(equalTo: tagPreviewContainerView.leadingAnchor),
                tagPreviewStackView.topAnchor.constraint(equalTo: tagPreviewContainerView.topAnchor),
                tagPreviewStackView.bottomAnchor.constraint(equalTo: tagPreviewContainerView.bottomAnchor),
                tagPreviewStackView.trailingAnchor.constraint(equalTo: tagPreviewContainerView.trailingAnchor),
                tagPreviewStackView.trailingAnchor.constraint(lessThanOrEqualTo: actionView.leadingAnchor, constant: -16),

                actionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                actionView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
            ])
        }

        private func configureTagPreviews(_ tags: [String]) {
            tagPreviewStackView.arrangedSubviews.forEach { view in
                tagPreviewStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            tagPreviewContainerView.isHidden = tags.isEmpty

            let visibleTags = Array(tags.prefix(maximumVisibleTagCount))
            let shouldShowOverflowPill = tags.count > visibleTags.count
            let shrinkableTagIndex = visibleTags.indices.last

            visibleTags.enumerated().forEach { index, tag in
                let compressionResistancePriority: UILayoutPriority = index == shrinkableTagIndex
                    ? .defaultLow
                    : .required
                tagPreviewStackView.addArrangedSubview(
                    makeTagPill(
                        text: tag,
                        horizontalCompressionResistancePriority: compressionResistancePriority
                    )
                )
            }

            if shouldShowOverflowPill {
                let hiddenTagCount = tags.count - visibleTags.count
                tagPreviewStackView.addArrangedSubview(
                    makeTagPill(
                        text: "+\(hiddenTagCount)",
                        horizontalCompressionResistancePriority: .required
                    )
                )
            }

            let spacerView = UIView()
            spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            tagPreviewStackView.addArrangedSubview(spacerView)
        }

        private func makeTagPill(
            text: String,
            horizontalCompressionResistancePriority: UILayoutPriority
        ) -> PillLabel {
            let label = PillLabel()
            label.text = text
            label.font = AppTheme.roundedFont(ofSize: 12, weight: .medium)
            label.textColor = AppTheme.tagText
            label.backgroundColor = AppTheme.controlBackground
            label.layer.cornerRadius = 9
            label.layer.masksToBounds = true
            label.lineBreakMode = .byTruncatingTail
            label.numberOfLines = 1
            label.setContentCompressionResistancePriority(horizontalCompressionResistancePriority, for: .horizontal)
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 120).isActive = true
            return label
        }

        private func makeLatestActivityText(
            activity: Activity,
            startTime: Date
        ) -> String {
            let dateText = ActivityDisplayFormatter.activityDateWithoutTimeText(for: startTime)
            let durationText = ActivityDisplayFormatter.roundedHistoryDurationText(
                for: activityDuration(for: activity)
            )
            return "\(dateText) : \(durationText)"
        }

        private func activityDuration(for activity: Activity) -> TimeInterval {
            if let timeTaken = activity.timeTaken {
                return timeTaken
            }

            guard
                let startTime = activity.activityStartTime,
                let completionTime = activity.activityCompletionTime
            else {
                return 0
            }

            return completionTime.timeIntervalSince(startTime)
        }
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()
    private lazy var settingsButton = UIBarButtonItem(
        image: UIImage(systemName: "gearshape"),
        primaryAction: UIAction { [weak self] _ in
            self?.settingsButtonTapped()
        }
    )
    private let tagsButton = UIButton(type: .system)
    private lazy var navigationTagsButton = UIBarButtonItem(customView: tagsButton)
    private var activityTypeRows: [ActivityTypeRow] = []
    private var selectedTagIDs: Set<UUID> = []
    private var didPromptForInitialActivityTypeCreation = false
#if DEBUG
    private var screenshotSampleActivityTypes: [ActivityType] = []
#endif

    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        registerForThemeChanges()
        configureTimerNotifications()
        configureSettingsNotifications()
        loadActivityTypes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
        loadActivityTypes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        promptForInitialActivityTypeIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAppearance() {
        title = "Activity Types"
        let navigationAddActivityTypeButton = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.addButtonTapped()
            }
        )
        configureTagsButton()
        settingsButton.accessibilityLabel = "Settings"
        navigationItem.rightBarButtonItems = [navigationAddActivityTypeButton, navigationTagsButton, settingsButton]

        configureTableView()
        configureEmptyStateLabel()
        applyTheme()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(ActivityTypeCell.self, forCellReuseIdentifier: ActivityTypeCell.reuseIdentifier)
    }

    private func configureEmptyStateLabel() {
        emptyStateLabel.text = "No activity types"
        emptyStateLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = AppTheme.metadataText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        tableView.backgroundColor = AppTheme.screenBackground
        tableView.separatorColor = AppTheme.separator
        navigationController?.navigationBar.tintColor = AppTheme.accent
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 34, weight: .bold)
        ]
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        updateTagsFilterIndicator()
    }

    private func navigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.screenBackground
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 34, weight: .bold)
        ]
        return appearance
    }

    private func configureTimerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeTimersDidChange),
            name: TimerSessionState.didChangeActiveTimersNotification,
            object: nil
        )
    }

    private func configureSettingsNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(durationDisplayDidChange),
            name: AppSettings.durationDisplayDidChangeNotification,
            object: nil
        )
    }

    private func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyTheme()
            viewController.tableView.reloadData()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: AppTheme.didChangeNotification,
            object: nil
        )
    }

    private func loadActivityTypes() {
#if DEBUG
        if !screenshotSampleActivityTypes.isEmpty {
            activityTypeRows = screenshotSampleActivityTypes
                .filter(matchesSelectedTags)
                .map(makeActivityTypeRow)
                .sorted(by: activityTypeSort)
            updateContent()
            return
        }
#endif
        guard let modelContext else {
            activityTypeRows = []
            updateContent()
            return
        }

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            activityTypeRows = activityTypes
                .filter(matchesSelectedTags)
                .map(makeActivityTypeRow)
                .sorted(by: activityTypeSort)
            updateContent()
        } catch {
            assertionFailure("Unable to load activity types: \(error)")
        }
    }

    private func makeActivityTypeRow(from activityType: ActivityType) -> ActivityTypeRow {
        let latestActivity = latestCompletedActivity(for: activityType)

        return ActivityTypeRow(
            activityType: activityType,
            name: activityType.name,
            latestActivity: latestActivity,
            latestActivityStartTime: latestActivity?.activityStartTime,
            timerState: TimerViewController.timerState(for: activityType),
            tagPreviewTexts: tagPreviewTexts(for: activityType)
        )
    }

    private func tagPreviewTexts(for activityType: ActivityType) -> [String] {
        activityType.tags?
            .map(\.name)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending } ?? []
    }

    private func matchesSelectedTags(_ activityType: ActivityType) -> Bool {
        guard !selectedTagIDs.isEmpty else {
            return true
        }

        let activityTypeTagIDs = Set(activityType.tags?.map(\.uniqueID) ?? [])
        return selectedTagIDs.allSatisfy { activityTypeTagIDs.contains($0) }
    }

    private func latestCompletedActivity(for activityType: ActivityType) -> Activity? {
        activityType.activities
            .filter { $0.activityStartTime != nil && $0.activityCompletionTime != nil }
            .sorted { lhs, rhs in
                guard let lhsStartTime = lhs.activityStartTime else {
                    return false
                }

                guard let rhsStartTime = rhs.activityStartTime else {
                    return true
                }

                return lhsStartTime > rhsStartTime
            }
            .first
    }

    private func activityTypeSort(
        _ lhs: ActivityTypeRow,
        _ rhs: ActivityTypeRow
    ) -> Bool {
        switch (lhs.latestActivityStartTime, rhs.latestActivityStartTime) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate > rhsDate
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func updateContent() {
        tableView.reloadData()
        emptyStateLabel.text = selectedTagIDs.isEmpty ? "No activity types" : "No activity types match the selected tags"
        emptyStateLabel.isHidden = !activityTypeRows.isEmpty
        updateTagsFilterIndicator()
    }

    private func promptForInitialActivityTypeIfNeeded() {
#if DEBUG
        guard screenshotSampleActivityTypes.isEmpty else {
            return
        }
#endif
        guard !didPromptForInitialActivityTypeCreation else {
            return
        }

        guard activityTypeRows.isEmpty else {
            return
        }

        didPromptForInitialActivityTypeCreation = true
        presentCreateActivityTypeAlert()
    }

    @objc private func activeTimersDidChange() {
        loadActivityTypes()
    }

    @objc private func durationDisplayDidChange() {
        loadActivityTypes()
    }

    @objc private func themeDidChange() {
        applyTheme()
        emptyStateLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = AppTheme.metadataText
        tableView.reloadData()
    }

    private func settingsButtonTapped() {
        let settingsViewController = SettingsViewController()
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = navigationController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.selectedDetentIdentifier = .large
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 18
        }

        present(navigationController, animated: true)
    }

    private func startActivityType(_ activityType: ActivityType) {
        presentTimerViewController(modelContext: modelContext, activityType: activityType, autoStart: true)
    }

    private func showTimerViewController(activityType: ActivityType) {
        presentTimerViewController(modelContext: modelContext, activityType: activityType)
    }

    private func viewAllActivities(for activityType: ActivityType) {
        let activityHistoryViewController = ActivityHistoryViewController(
            nibName: "ActivityHistoryViewController",
            bundle: nil
        )
        activityHistoryViewController.modelContext = modelContext
        activityHistoryViewController.activityType = activityType
        navigationController?.pushViewController(activityHistoryViewController, animated: true)
    }

    private func deleteActivityType(_ activityType: ActivityType) throws {
#if DEBUG
        guard screenshotSampleActivityTypes.isEmpty else {
            return
        }
#endif
        guard let modelContext else {
            return
        }

        TimerViewController.removeTimerControlsView(for: activityType.uniqueID)
        deleteTimerCaches(activityTypeID: activityType.uniqueID)
        modelContext.delete(activityType)
        try modelContext.save()
        loadActivityTypes()
    }

    private func deleteTimerCaches(activityTypeID: UUID) {
        guard let modelContext else {
            return
        }

        do {
            let matchingCaches = try modelContext.fetch(FetchDescriptor<ActivityTimerCache>())
                .filter { $0.activityTypeUniqueID == activityTypeID }
            matchingCaches.forEach(modelContext.delete)
        } catch {
            assertionFailure("Unable to delete activity timer cache: \(error)")
        }
    }

    private func presentDeleteActivityTypeAlert(
        for activityType: ActivityType,
        completion: @escaping (Bool) -> Void
    ) {
        let activityCount = activityType.activities.count
        let alertController = UIAlertController(
            title: "Delete Activity Type?",
            message: deleteActivityTypeAlertMessage(
                activityType: activityType,
                activityCount: activityCount,
                hasActiveTimer: TimerViewController.hasRunningOrPausedTimer(for: activityType)
            ),
            preferredStyle: .alert
        )

        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                do {
                    try self?.deleteActivityType(activityType)
                    completion(true)
                } catch {
                    assertionFailure("Unable to delete activity type: \(error)")
                    self?.presentDeleteActivityTypeErrorAlert()
                    completion(false)
                }
            }
        )

        present(alertController, animated: true)
    }

    private func deleteActivityTypeAlertMessage(
        activityType: ActivityType,
        activityCount: Int,
        hasActiveTimer: Bool
    ) -> String {
        let activityText = activityCount == 1 ? "activity" : "activities"

        if activityCount == 0 && hasActiveTimer {
            return "\(activityType.name) has no linked activities, but there is an active timer for this activity. Deleting it will also remove that timer."
        }

        if hasActiveTimer {
            return "\(activityType.name) has \(activityCount) linked \(activityText) and an active timer. Deleting it will delete those activities and remove the timer."
        }

        return "\(activityType.name) has \(activityCount) linked \(activityText). Deleting it will also delete those activities."
    }

    private func presentDeleteActivityTypeErrorAlert() {
        let alertController = UIAlertController(
            title: "Unable to Delete Activity Type",
            message: "Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func addButtonTapped() {
        presentCreateActivityTypeAlert()
    }

    private func configureTagsButton() {
        tagsButton.addAction(
            UIAction { [weak self] _ in
                self?.presentTagsManagementSheet()
            },
            for: .touchUpInside
        )
        updateTagsFilterIndicator()
    }

    private func updateTagsFilterIndicator() {
        let isFiltering = !selectedTagIDs.isEmpty
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: isFiltering ? "tag.fill" : "tag")
        configuration.imagePadding = 4
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = AppTheme.accent
        configuration.background.backgroundColor = isFiltering ? AppTheme.controlBackground : .clear
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 7, bottom: 5, trailing: 7)

        if isFiltering {
            configuration.title = "\(selectedTagIDs.count)"
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var updatedAttributes = attributes
                updatedAttributes.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
                return updatedAttributes
            }
        }

        tagsButton.configuration = configuration
        tagsButton.accessibilityLabel = isFiltering
            ? "Filtered by \(selectedTagIDs.count) tags. Manage Tags"
            : "Manage Tags"
    }

    private func presentTagsManagementSheet() {
        let tagsManagementViewController = TagsManagementViewController()
        tagsManagementViewController.modelContext = modelContext
        tagsManagementViewController.emptyStateMessage = TagsManagementViewController.activityTypeEmptyStateMessage
        tagsManagementViewController.selectedTagIDs = selectedTagIDs
        tagsManagementViewController.onSelectionChange = { [weak self] selectedTagIDs in
            self?.selectedTagIDs = selectedTagIDs
            self?.loadActivityTypes()
        }
        tagsManagementViewController.onTagsChange = { [weak self] in
            self?.loadActivityTypes()
        }
        tagsManagementViewController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = tagsManagementViewController.sheetPresentationController {
            let compactDetentIdentifier = UISheetPresentationController.Detent.Identifier("compactTags")
            sheetPresentationController.detents = [
                .custom(identifier: compactDetentIdentifier) { _ in 320 },
                .large()
            ]
            sheetPresentationController.selectedDetentIdentifier = compactDetentIdentifier
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 18
        }

        present(tagsManagementViewController, animated: true)
    }

    private func presentCreateActivityTypeAlert() {
#if DEBUG
        guard screenshotSampleActivityTypes.isEmpty else {
            return
        }
#endif
        let existingNames = fetchExistingActivityTypeNames()
        let alertController = UIAlertController(
            title: "New Activity Type",
            message: "Enter an activity type name.",
            preferredStyle: .alert
        )
        alertController.view.tintColor = AppTheme.primaryText

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let name = alertController?.textFields?.first?.text else {
                return
            }

            self?.createActivityType(named: name)
        }
        submitAction.isEnabled = false

        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Activity type name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.addAction(
                UIAction { [weak self, weak textField] _ in
                    submitAction.isEnabled = self?.isUniqueActivityTypeName(
                        textField?.text,
                        existingNames: existingNames
                    ) ?? false
                },
                for: .editingChanged
            )
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(submitAction)
        present(alertController, animated: true)
    }

    private func createActivityType(named name: String) {
        guard let modelContext else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUniqueActivityTypeName(trimmedName, existingNames: fetchExistingActivityTypeNames()) else {
            presentCreateActivityTypeAlert()
            return
        }

        let activityType = ActivityType(name: trimmedName)
        modelContext.insert(activityType)

        do {
            try modelContext.save()
            loadActivityTypes()
        } catch {
            modelContext.delete(activityType)
            assertionFailure("Unable to save activity type: \(error)")
            presentCreateActivityTypeAlert()
        }
    }

    private func fetchExistingActivityTypeNames() -> Set<String> {
#if DEBUG
        if !screenshotSampleActivityTypes.isEmpty {
            return Set(screenshotSampleActivityTypes.map { normalizeActivityTypeName($0.name) })
        }
#endif
        guard let modelContext else {
            return []
        }

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            return Set(activityTypes.map { normalizeActivityTypeName($0.name) })
        } catch {
            assertionFailure("Unable to fetch activity type names: \(error)")
            return []
        }
    }

    private func isUniqueActivityTypeName(
        _ name: String?,
        existingNames: Set<String>
    ) -> Bool {
        let normalizedName = normalizeActivityTypeName(name)
        return !normalizedName.isEmpty && !existingNames.contains(normalizedName)
    }

    private func normalizeActivityTypeName(_ name: String?) -> String {
        name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedLowercase ?? ""
    }

#if DEBUG
    func configureForScreenshotSample(
        activityTypes: [ActivityType],
        selectedTagIDs: Set<UUID>
    ) {
        screenshotSampleActivityTypes = activityTypes
        self.selectedTagIDs = selectedTagIDs
        modelContext = nil
        didPromptForInitialActivityTypeCreation = true

        if isViewLoaded {
            loadActivityTypes()
        }
    }
#endif
}

extension ActivityTypesViewController: FloatingTimerButtonContextProviding {
    var floatingTimerButtonContext: FloatingTimerButtonContext? {
        TimerViewController.hasActiveOrRecentTimerControls() ? .globalTimers : nil
    }
}

extension ActivityTypesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activityTypeRows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ActivityTypeCell.reuseIdentifier,
            for: indexPath
        ) as? ActivityTypeCell
        let row = activityTypeRows[indexPath.row]
        cell?.configure(with: row)
        cell?.onStartTapped = { [weak self] in
            self?.startActivityType(row.activityType)
        }
        cell?.onTimerStatusTapped = { [weak self] in
            self?.showTimerViewController(activityType: row.activityType)
        }
        return cell ?? UITableViewCell()
    }
}

extension ActivityTypesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        viewAllActivities(for: activityTypeRows[indexPath.row].activityType)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        makeDeleteSwipeActionsConfiguration(for: indexPath)
    }

    private func makeDeleteSwipeActionsConfiguration(for indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let row = activityTypeRows[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.presentDeleteActivityTypeAlert(for: row.activityType, completion: completion)
        }

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
