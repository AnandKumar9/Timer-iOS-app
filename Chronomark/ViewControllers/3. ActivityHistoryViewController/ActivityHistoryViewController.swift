import UIKit
import SwiftData

final class ActivityHistoryViewController: UIViewController {
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

    private final class ActivityHistoryCell: UITableViewCell {
        static let reuseIdentifier = "ActivityHistoryCell"

        private let activitySummaryLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: ActivityHistoryRow) {
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground
            activitySummaryLabel.attributedText = makeActivitySummaryText(
                dateText: row.startTimeText,
                durationText: row.durationText
            )
        }

        private func configureCell() {
            selectionStyle = .none
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground

            activitySummaryLabel.numberOfLines = 1
            activitySummaryLabel.adjustsFontSizeToFitWidth = true
            activitySummaryLabel.minimumScaleFactor = 0.75
            activitySummaryLabel.lineBreakMode = .byClipping
            activitySummaryLabel.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(activitySummaryLabel)

            NSLayoutConstraint.activate([
                activitySummaryLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                activitySummaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
                activitySummaryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
                activitySummaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
            ])
        }

        private func makeActivitySummaryText(
            dateText: String,
            durationText: String
        ) -> NSAttributedString {
            let summaryText = "\(dateText) : \(durationText)"
            let attributedText = NSMutableAttributedString(
                string: summaryText,
                attributes: [
                    .font: AppTheme.roundedFont(ofSize: 14, weight: .regular),
                    .foregroundColor: AppTheme.metadataText
                ]
            )

            let durationRange = (summaryText as NSString).range(of: durationText)
            attributedText.addAttributes(
                [
                    .font: AppTheme.roundedFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: AppTheme.durationText
                ],
                range: durationRange
            )

            return attributedText
        }
    }

    private struct ActivityHistoryRow {
        let activity: Activity
        let startTimeText: String
        let duration: TimeInterval
        let durationText: String
    }

    private let headerStackView = UIStackView()
    private let activityNameLabel = UILabel()
    private let tagPreviewContainerView = UIView()
    private let tagPreviewStackView = UIStackView()
    private let activityStatsLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()
    private var activityRows: [ActivityHistoryRow] = []
    private let maximumVisibleTagCount = 4
#if DEBUG
    private var isUsingScreenshotSamples = false
#endif

    var modelContext: ModelContext?
    var activityType: ActivityType?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        registerForThemeChanges()
        configureSettingsNotifications()
        loadActivities()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
        loadActivities()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAppearance() {
        title = "Activity History"
        let tagsButton = UIBarButtonItem(
            image: UIImage(systemName: "tag"),
            primaryAction: UIAction { [weak self] _ in
                self?.presentTagsSheet()
            }
        )
        tagsButton.accessibilityLabel = "Edit Tags"
        navigationItem.rightBarButtonItem = tagsButton

        configureActivityNameLabel()
        configureTagPreviewStackView()
        configureActivityStatsLabel()
        configureTableView()
        configureEmptyStateLabel()
        configureActivityNotifications()
        applyTheme()

        headerStackView.axis = .vertical
        headerStackView.alignment = .fill
        headerStackView.spacing = 8
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerStackView.addArrangedSubview(activityNameLabel)
        headerStackView.addArrangedSubview(tagPreviewContainerView)
        headerStackView.addArrangedSubview(activityStatsLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStackView)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func configureActivityNameLabel() {
        activityNameLabel.text = activityType?.name ?? "Activity"
        activityNameLabel.font = AppTheme.roundedFont(ofSize: 34, weight: .bold)
        activityNameLabel.textColor = AppTheme.primaryText
        activityNameLabel.numberOfLines = 1
        activityNameLabel.adjustsFontSizeToFitWidth = true
        activityNameLabel.minimumScaleFactor = 0.55
        activityNameLabel.lineBreakMode = .byClipping
        activityNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        activityNameLabel.isUserInteractionEnabled = true
        activityNameLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(activityNameLabelTapped))
        )
    }

    private func configureActivityStatsLabel() {
        activityStatsLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .medium)
        activityStatsLabel.textColor = AppTheme.metadataText
        activityStatsLabel.numberOfLines = 1
        activityStatsLabel.adjustsFontSizeToFitWidth = true
        activityStatsLabel.minimumScaleFactor = 0.8
        activityStatsLabel.lineBreakMode = .byClipping
    }

    private func configureTagPreviewStackView() {
        tagPreviewStackView.axis = .horizontal
        tagPreviewStackView.alignment = .center
        tagPreviewStackView.spacing = 6
        tagPreviewStackView.translatesAutoresizingMaskIntoConstraints = false

        tagPreviewContainerView.addSubview(tagPreviewStackView)
        tagPreviewContainerView.isHidden = true
        tagPreviewContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tagPreviewStackView.leadingAnchor.constraint(equalTo: tagPreviewContainerView.leadingAnchor),
            tagPreviewStackView.topAnchor.constraint(equalTo: tagPreviewContainerView.topAnchor),
            tagPreviewStackView.bottomAnchor.constraint(equalTo: tagPreviewContainerView.bottomAnchor),
            tagPreviewStackView.trailingAnchor.constraint(equalTo: tagPreviewContainerView.trailingAnchor)
        ])
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.backgroundColor = AppTheme.screenBackground
        tableView.separatorColor = AppTheme.separator
        tableView.register(ActivityHistoryCell.self, forCellReuseIdentifier: ActivityHistoryCell.reuseIdentifier)
    }

    private func configureEmptyStateLabel() {
        emptyStateLabel.text = "No completed activities"
        emptyStateLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = AppTheme.metadataText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        headerStackView.backgroundColor = AppTheme.screenBackground
        tableView.backgroundColor = AppTheme.screenBackground
        tableView.separatorColor = AppTheme.separator
        activityNameLabel.textColor = AppTheme.primaryText
        activityStatsLabel.textColor = AppTheme.metadataText
        emptyStateLabel.textColor = AppTheme.metadataText
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

    private func configureActivityNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activityDidPersist(_:)),
            name: TimerSessionState.didPersistActivityNotification,
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
    }

    private func loadActivities() {
        activityNameLabel.text = activityType?.name ?? "Activity"

        guard let activityType else {
            activityRows = []
            configureTagPreviews([])
            updateActivityStats()
            updateContent()
            return
        }

        configureTagPreviews(tagPreviewTexts(for: activityType))
        activityRows = activityType.activities
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
            .compactMap(makeActivityHistoryRow)
        updateActivityStats()
        updateContent()
    }

    private func updateActivityStats() {
        let activityCount = activityRows.count
        let activityText = activityCount == 1 ? "1 activity" : "\(activityCount) activities"
        let averageText = averageActivityDurationText()
        activityStatsLabel.text = "\(activityText), Avg time: \(averageText)"
    }

    private func averageActivityDurationText() -> String {
        let durations = activityRows.map(\.duration)

        guard !durations.isEmpty else {
            return "0 min"
        }

        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        return ActivityDisplayFormatter.roundedHistoryDurationText(for: averageDuration)
    }

    private func tagPreviewTexts(for activityType: ActivityType) -> [String] {
        activityType.tags?
            .map(\.name)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending } ?? []
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
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tagPreviewTapped))
        )
        return label
    }

    private func makeActivityHistoryRow(from activity: Activity) -> ActivityHistoryRow? {
        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return nil
        }

        let duration = activityDuration(for: activity, completionTime: completionTime)

        return ActivityHistoryRow(
            activity: activity,
            startTimeText: activityHistoryDateText(for: startTime),
            duration: duration,
            durationText: ActivityDisplayFormatter.roundedHistoryDurationText(for: duration)
        )
    }

    private func activityHistoryDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM dd (EEE)  hh:mm a"
        return formatter.string(from: date)
    }

    private func activityDuration(for activity: Activity, completionTime: Date) -> TimeInterval {
        if let timeTaken = activity.timeTaken {
            return timeTaken
        }

        guard let startTime = activity.activityStartTime else {
            return 0
        }

        return completionTime.timeIntervalSince(startTime)
    }

    private func presentDeleteActivityAlert(for row: ActivityHistoryRow, completion: @escaping (Bool) -> Void) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            completion(false)
            return
        }
#endif
        let alertController = UIAlertController(
            title: "Delete Activity?",
            message: "Delete \(row.startTimeText) : \(row.durationText)?",
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
                    try self?.deleteActivity(row.activity)
                    completion(true)
                } catch {
                    assertionFailure("Unable to delete activity: \(error)")
                    self?.presentDeleteActivityErrorAlert()
                    completion(false)
                }
            }
        )

        present(alertController, animated: true)
    }

    private func presentRenameActivityTypeAlert() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard let activityType else {
            return
        }

        let existingNames = fetchExistingActivityTypeNames(excluding: activityType)
        let alertController = UIAlertController(
            title: "Rename Activity Type",
            message: nil,
            preferredStyle: .alert
        )

        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self, weak alertController] _ in
            guard let name = alertController?.textFields?.first?.text else {
                return
            }

            self?.renameActivityType(to: name)
        }
        renameAction.isEnabled = false

        alertController.addTextField { [weak self] textField in
            textField.text = activityType.name
            textField.placeholder = "Activity type name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.addAction(
                UIAction { [weak self, weak textField] _ in
                    renameAction.isEnabled = self?.isValidActivityTypeName(
                        textField?.text,
                        existingNames: existingNames
                    ) ?? false
                },
                for: .editingChanged
            )
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(renameAction)
        present(alertController, animated: true)
    }

    private func presentTagsSheet() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard let activityType else {
            return
        }

        let hasTags = hasExistingTags()
        let tagsViewController = TagsManagementViewController()
        tagsViewController.modelContext = modelContext
        tagsViewController.sheetTitle = "Tags for \(activityType.name)"
        tagsViewController.emptyStateMessage = TagsManagementViewController.activityTypeEmptyStateMessage
        tagsViewController.selectedTagIDs = Set(activityType.tags?.map(\.uniqueID) ?? [])
        tagsViewController.primaryActionMode = hasTags ? .saveSelection : .createTag
        tagsViewController.groupsSelectedTagsFirst = hasTags
        tagsViewController.commitsSelectionImmediately = !hasTags
        tagsViewController.allowsTagManagement = !hasTags
        tagsViewController.selectsCreatedTags = !hasTags
        tagsViewController.switchesToSaveSelectionAfterCreatingTag = !hasTags
        tagsViewController.onTagCreate = { [weak self] tag in
            self?.attachCreatedTag(tag)
        }
        tagsViewController.onSaveSelection = { [weak self] selectedTagIDs in
            self?.saveTags(selectedTagIDs)
        }
        tagsViewController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = tagsViewController.sheetPresentationController {
            let compactDetentIdentifier = UISheetPresentationController.Detent.Identifier("compactTags")
            sheetPresentationController.detents = [
                .custom(identifier: compactDetentIdentifier) { _ in 320 },
                .large()
            ]
            sheetPresentationController.selectedDetentIdentifier = compactDetentIdentifier
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 18
        }

        present(tagsViewController, animated: true)
    }

    private func hasExistingTags() -> Bool {
        guard let modelContext else {
            return false
        }

        do {
            return try !modelContext.fetch(FetchDescriptor<ActivityTag>()).isEmpty
        } catch {
            assertionFailure("Unable to fetch tags: \(error)")
            return false
        }
    }

    private func attachCreatedTag(_ tag: ActivityTag) {
        guard let modelContext, let activityType else {
            return
        }

        if activityType.tags == nil {
            activityType.tags = []
        }

        guard activityType.tags?.contains(where: { $0.uniqueID == tag.uniqueID }) == false else {
            return
        }

        activityType.tags?.append(tag)
        activityType.tags?.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        do {
            try modelContext.save()
            TimerSessionState.notifyActivityPersisted(activityTypeID: activityType.uniqueID)
        } catch {
            assertionFailure("Unable to attach created tag: \(error)")
            presentSaveTagsErrorAlert()
        }
    }

    private func saveTags(_ selectedTagIDs: Set<UUID>) {
        guard let modelContext, let activityType else {
            return
        }

        do {
            let tags = try modelContext.fetch(FetchDescriptor<ActivityTag>())
            activityType.tags = tags
                .filter { selectedTagIDs.contains($0.uniqueID) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            try modelContext.save()
            TimerSessionState.notifyActivityPersisted(activityTypeID: activityType.uniqueID)
        } catch {
            assertionFailure("Unable to save activity type tags: \(error)")
            presentSaveTagsErrorAlert()
        }
    }

    private func renameActivityType(to name: String) {
        guard let modelContext, let activityType else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidActivityTypeName(
            trimmedName,
            existingNames: fetchExistingActivityTypeNames(excluding: activityType)
        ) else {
            presentRenameActivityTypeAlert()
            return
        }

        let previousName = activityType.name
        activityType.name = trimmedName

        do {
            try modelContext.save()
            activityNameLabel.text = trimmedName
            TimerSessionState.notifyActivityPersisted(activityTypeID: activityType.uniqueID)
        } catch {
            activityType.name = previousName
            assertionFailure("Unable to rename activity type: \(error)")
            presentRenameActivityTypeErrorAlert()
        }
    }

    private func deleteActivity(_ activity: Activity) throws {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard let modelContext else {
            return
        }

        let activityTypeID = activity.activityType.uniqueID
        activity.activityType.activities.removeAll { $0 === activity }
        modelContext.delete(activity)
        try modelContext.save()
        TimerSessionState.notifyActivityPersisted(activityTypeID: activityTypeID)
        loadActivities()
    }

    private func presentDeleteActivityErrorAlert() {
        let alertController = UIAlertController(
            title: "Unable to Delete Activity",
            message: "Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func presentRenameActivityTypeErrorAlert() {
        let alertController = UIAlertController(
            title: "Unable to Rename Activity Type",
            message: "Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func presentSaveTagsErrorAlert() {
        let alertController = UIAlertController(
            title: "Unable to Save Tags",
            message: "Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func fetchExistingActivityTypeNames(excluding activityType: ActivityType) -> Set<String> {
        guard let modelContext else {
            return []
        }

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            return Set(
                activityTypes
                    .filter { $0.uniqueID != activityType.uniqueID }
                    .map { normalizeActivityTypeName($0.name) }
            )
        } catch {
            assertionFailure("Unable to fetch activity type names: \(error)")
            return []
        }
    }

    private func isValidActivityTypeName(
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
    func configureForScreenshotSample(activityType: ActivityType?) {
        isUsingScreenshotSamples = true
        modelContext = nil
        self.activityType = activityType

        if isViewLoaded {
            loadActivities()
        }
    }
#endif

    private func updateContent() {
        tableView.reloadData()
        emptyStateLabel.isHidden = !activityRows.isEmpty
    }

    @objc private func activityDidPersist(_ notification: Notification) {
        guard
            let activityTypeID = notification.userInfo?[TimerSessionState.activityTypeIDUserInfoKey] as? UUID,
            activityTypeID == activityType?.uniqueID
        else {
            return
        }

        loadActivities()
    }

    @objc private func durationDisplayDidChange() {
        loadActivities()
    }

    @objc private func activityNameLabelTapped() {
        guard activityType != nil else {
            return
        }

        presentRenameActivityTypeAlert()
    }

    @objc private func tagPreviewTapped() {
        guard activityType != nil else {
            return
        }

        presentTagsSheet()
    }

}

extension ActivityHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activityRows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ActivityHistoryCell.reuseIdentifier,
            for: indexPath
        ) as? ActivityHistoryCell
        cell?.configure(with: activityRows[indexPath.row])
        return cell ?? UITableViewCell()
    }
}

extension ActivityHistoryViewController: FloatingTimerButtonContextProviding {
    var floatingTimerButtonContext: FloatingTimerButtonContext? {
        guard let activityType else {
            return nil
        }

        return .activityType(activityType)
    }
}

extension ActivityHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showActivityDetails(for: activityRows[indexPath.row].activity)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        makeDeleteSwipeActionsConfiguration(for: indexPath)
    }

    private func makeDeleteSwipeActionsConfiguration(for indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let row = activityRows[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.presentDeleteActivityAlert(for: row, completion: completion)
        }

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func showActivityDetails(for activity: Activity) {
        let activityDetailsViewController = ActivityDetailsViewController(
            nibName: "ActivityDetailsViewController",
            bundle: nil
        )
        activityDetailsViewController.modelContext = modelContext
        activityDetailsViewController.activity = activity
        navigationController?.pushViewController(activityDetailsViewController, animated: true)
    }
}
