import UIKit
import SwiftData

final class SummarizeMyDayViewController: UIViewController {
    private final class DaySummaryCell: UITableViewCell {
        static let reuseIdentifier = "DaySummaryCell"

        private let timeLabel = UILabel()
        private let activityNameLabel = UILabel()
        private let statusImageView = UIImageView()
        private let durationLabel = UILabel()
        private let noteLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: DaySummaryRow) {
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground

            timeLabel.text = row.timeRangeText
            timeLabel.textColor = AppTheme.metadataText
            activityNameLabel.text = row.activityTypeName
            activityNameLabel.textColor = AppTheme.primaryText
            configureStatusIcon(row.timerState)
            durationLabel.text = row.durationText
            durationLabel.textColor = AppTheme.durationText

            if let note = row.noteText {
                noteLabel.text = note
                noteLabel.isHidden = false
            } else {
                noteLabel.text = nil
                noteLabel.isHidden = true
            }
        }

        private func configureCell() {
            backgroundColor = AppTheme.screenBackground
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground
            contentView.backgroundColor = AppTheme.screenBackground

            timeLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .medium)
            timeLabel.numberOfLines = 2
            timeLabel.setContentHuggingPriority(.required, for: .horizontal)
            timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            activityNameLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .semibold)
            activityNameLabel.numberOfLines = 1
            activityNameLabel.adjustsFontSizeToFitWidth = true
            activityNameLabel.minimumScaleFactor = 0.8

            statusImageView.contentMode = .scaleAspectFit
            statusImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            statusImageView.setContentHuggingPriority(.required, for: .horizontal)
            statusImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            statusImageView.isHidden = true

            durationLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .semibold)
            durationLabel.numberOfLines = 1
            durationLabel.textAlignment = .right
            durationLabel.setContentHuggingPriority(.required, for: .horizontal)
            durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            noteLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .regular)
            noteLabel.textColor = AppTheme.metadataText
            noteLabel.numberOfLines = 2
            noteLabel.lineBreakMode = .byTruncatingTail

            let durationStackView = UIStackView(arrangedSubviews: [statusImageView, durationLabel])
            durationStackView.axis = .horizontal
            durationStackView.alignment = .center
            durationStackView.spacing = 5
            durationStackView.setContentHuggingPriority(.required, for: .horizontal)
            durationStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

            let titleStackView = UIStackView(arrangedSubviews: [activityNameLabel, durationStackView])
            titleStackView.axis = .horizontal
            titleStackView.alignment = .center
            titleStackView.spacing = 12

            let detailStackView = UIStackView(arrangedSubviews: [titleStackView, noteLabel])
            detailStackView.axis = .vertical
            detailStackView.alignment = .fill
            detailStackView.spacing = 5

            let rowStackView = UIStackView(arrangedSubviews: [timeLabel, detailStackView])
            rowStackView.axis = .horizontal
            rowStackView.alignment = .top
            rowStackView.spacing = 16
            rowStackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(rowStackView)

            NSLayoutConstraint.activate([
                timeLabel.widthAnchor.constraint(equalToConstant: 76),
                statusImageView.widthAnchor.constraint(equalToConstant: 18),
                statusImageView.heightAnchor.constraint(equalToConstant: 18),

                rowStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                rowStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                rowStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
                rowStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
            ])
        }

        private func configureStatusIcon(_ timerState: ActivityTimerState?) {
            guard let timerState else {
                statusImageView.image = nil
                statusImageView.accessibilityLabel = nil
                statusImageView.isHidden = true
                return
            }

            switch timerState {
            case .none:
                statusImageView.image = nil
                statusImageView.accessibilityLabel = nil
                statusImageView.isHidden = true
            case .running:
                statusImageView.image = UIImage(systemName: "timer")
                statusImageView.tintColor = AppTheme.accent
                statusImageView.accessibilityLabel = "Timer running"
                statusImageView.isHidden = false
            case .paused:
                statusImageView.image = UIImage(systemName: "pause.circle.fill")
                statusImageView.tintColor = AppTheme.paused
                statusImageView.accessibilityLabel = "Timer paused"
                statusImageView.isHidden = false
            }
        }
    }

    private struct DaySummaryRow {
        enum Source {
            case completed(Activity)
            case cachedTimer(ActivityTimerCache)
        }

        let source: Source
        let startTime: Date
        let activityTypeName: String
        let timeRangeText: String
        let durationText: String
        let timerState: ActivityTimerState?
        let noteText: String?
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerStackView = UIStackView()
    private let previousDayButton = UIButton(type: .system)
    private let summaryLabel = UILabel()
    private let dayPickerButton = UIButton(type: .system)
    private let nextDayButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    private var activityRows: [DaySummaryRow] = []
    private var selectedDay: Date

    var modelContext: ModelContext?

    init(day: Date = .now) {
        self.selectedDay = day
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.selectedDay = .now
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        registerForThemeChanges()
        configureNotifications()
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
        title = "Summarize My Day"
        navigationItem.largeTitleDisplayMode = .never

        configurePreviousDayButton()
        configureSummaryLabel()
        configureDayPickerButton()
        configureNextDayButton()
        configureHeaderStackView()
        configureTableView()
        configureEmptyStateLabel()
        applyTheme()

        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStackView)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    private func configureSummaryLabel() {
        summaryLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .medium)
        summaryLabel.textColor = AppTheme.metadataText
        summaryLabel.numberOfLines = 1
        summaryLabel.adjustsFontSizeToFitWidth = true
        summaryLabel.minimumScaleFactor = 0.8
    }

    private func configurePreviousDayButton() {
        configureDayNavigationButton(
            previousDayButton,
            systemImageName: "chevron.left",
            accessibilityLabel: "Previous Day",
            action: UIAction { [weak self] _ in
                self?.selectRelativeDay(offset: -1)
            }
        )
    }

    private func configureDayPickerButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "calendar")
        configuration.baseForegroundColor = AppTheme.accent
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        dayPickerButton.configuration = configuration
        dayPickerButton.accessibilityLabel = "Select Day"
        dayPickerButton.setContentHuggingPriority(.required, for: .horizontal)
        dayPickerButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        dayPickerButton.addAction(
            UIAction { [weak self] _ in
                self?.presentDayPicker()
            },
            for: .touchUpInside
        )
    }

    private func configureNextDayButton() {
        configureDayNavigationButton(
            nextDayButton,
            systemImageName: "chevron.right",
            accessibilityLabel: "Next Day",
            action: UIAction { [weak self] _ in
                self?.selectRelativeDay(offset: 1)
            }
        )
    }

    private func configureDayNavigationButton(
        _ button: UIButton,
        systemImageName: String,
        accessibilityLabel: String,
        action: UIAction
    ) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: systemImageName)
        configuration.baseForegroundColor = AppTheme.accent
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.configuration = configuration
        button.accessibilityLabel = accessibilityLabel
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.widthAnchor.constraint(equalToConstant: 36).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addAction(action, for: .touchUpInside)
    }

    private func configureHeaderStackView() {
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 8
        headerStackView.addArrangedSubview(previousDayButton)
        headerStackView.addArrangedSubview(summaryLabel)
        headerStackView.addArrangedSubview(dayPickerButton)
        headerStackView.addArrangedSubview(nextDayButton)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.register(DaySummaryCell.self, forCellReuseIdentifier: DaySummaryCell.reuseIdentifier)
    }

    private func configureEmptyStateLabel() {
        emptyStateLabel.text = "No activities for this day"
        emptyStateLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        tableView.backgroundColor = AppTheme.screenBackground
        tableView.separatorColor = AppTheme.separator
        summaryLabel.textColor = AppTheme.metadataText
        previousDayButton.tintColor = AppTheme.accent
        dayPickerButton.tintColor = AppTheme.accent
        nextDayButton.tintColor = AppTheme.accent
        emptyStateLabel.textColor = AppTheme.metadataText
        navigationController?.navigationBar.tintColor = AppTheme.accent
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
        return appearance
    }

    private func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyTheme()
            viewController.tableView.reloadData()
        }
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activityDidPersist),
            name: TimerSessionState.didPersistActivityNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeTimersDidChange),
            name: TimerSessionState.didChangeActiveTimersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(durationDisplayDidChange),
            name: AppSettings.durationDisplayDidChangeNotification,
            object: nil
        )
    }

    private func loadActivities() {
        guard let modelContext else {
            activityRows = []
            updateContent()
            return
        }

        do {
            let activities = try modelContext.fetch(FetchDescriptor<Activity>())
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            let activityTypesByID = Dictionary(
                uniqueKeysWithValues: activityTypes.map { ($0.uniqueID, $0) }
            )
            let cachedTimers = try modelContext.fetch(FetchDescriptor<ActivityTimerCache>())
            let completedRows = activities
                .filter(isCompletedActivityInDay)
                .compactMap(makeDaySummaryRow)
            let cachedTimerRows = cachedTimers
                .filter(isCachedTimerInDay)
                .compactMap { cache in
                    makeDaySummaryRow(
                        from: cache,
                        activityType: activityTypesByID[cache.activityTypeUniqueID]
                    )
                }

            activityRows = (completedRows + cachedTimerRows)
                .sorted { $0.startTime < $1.startTime }
            updateContent()
        } catch {
            assertionFailure("Unable to fetch day summary activities: \(error)")
            activityRows = []
            updateContent()
        }
    }

    private func isCompletedActivityInDay(_ activity: Activity) -> Bool {
        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return false
        }

        return intervalOverlapsSelectedDay(startTime: startTime, endTime: completionTime)
    }

    private func isCachedTimerInDay(_ cache: ActivityTimerCache) -> Bool {
        intervalOverlapsSelectedDay(
            startTime: cache.startTime,
            endTime: cachedTimerEndTime(for: cache)
        )
    }

    private func intervalOverlapsSelectedDay(startTime: Date, endTime: Date) -> Bool {
        let bounds = selectedDayBounds()
        return startTime < bounds.end && endTime >= bounds.start
    }

    private func selectedDayBounds() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDay)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    private func makeDaySummaryRow(from activity: Activity) -> DaySummaryRow? {
        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return nil
        }

        let duration = activityDuration(for: activity, completionTime: completionTime)

        return DaySummaryRow(
            source: .completed(activity),
            startTime: startTime,
            activityTypeName: activity.activityType.name,
            timeRangeText: timeRangeText(startTime: startTime, completionTime: completionTime),
            durationText: ActivityDisplayFormatter.roundedHistoryDurationText(for: duration),
            timerState: nil,
            noteText: normalizedNote(activity.activityNotes)
        )
    }

    private func makeDaySummaryRow(
        from cache: ActivityTimerCache,
        activityType: ActivityType?
    ) -> DaySummaryRow? {
        guard let activityType else {
            return nil
        }

        return DaySummaryRow(
            source: .cachedTimer(cache),
            startTime: cache.startTime,
            activityTypeName: activityType.name,
            timeRangeText: cachedTimerTimeRangeText(for: cache),
            durationText: ActivityDisplayFormatter.roundedHistoryDurationText(
                for: cachedTimerDuration(for: cache)
            ),
            timerState: cache.isRunning ? .running : .paused,
            noteText: nil
        )
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

    private func timeRangeText(startTime: Date, completionTime: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime))\n\(formatter.string(from: completionTime))"
    }

    private func cachedTimerTimeRangeText(for cache: ActivityTimerCache) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: cache.startTime))\n\(cache.isRunning ? "Now" : "Paused")"
    }

    private func cachedTimerDuration(for cache: ActivityTimerCache) -> TimeInterval {
        guard cache.isRunning else {
            return cache.timeElapsed
        }

        return cache.timeElapsed + Date().timeIntervalSince(cache.lastUpdateTime)
    }

    private func cachedTimerEndTime(for cache: ActivityTimerCache) -> Date {
        cache.isRunning ? Date() : cache.lastUpdateTime
    }

    private func normalizedNote(_ note: String?) -> String? {
        guard let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedNote.isEmpty
        else {
            return nil
        }

        return trimmedNote
    }

    private func updateContent() {
        updateSummary()
        tableView.reloadData()
        emptyStateLabel.isHidden = !activityRows.isEmpty
    }

    private func updateSummary() {
        let dayText = ActivityDisplayFormatter.activityDateWithoutTimeText(for: selectedDay)
        let activityText = activityRows.count == 1 ? "1 activity" : "\(activityRows.count) activities"
        summaryLabel.text = "\(dayText) : \(activityText)"
        updateDayNavigationButtons()
    }

    private func updateDayNavigationButtons() {
        nextDayButton.isEnabled = !isSelectedDayToday()
        nextDayButton.alpha = nextDayButton.isEnabled ? 1 : 0.35
    }

    private func presentDayPicker() {
        let pickerViewController = UIViewController()
        pickerViewController.title = "Select Day"
        pickerViewController.view.backgroundColor = AppTheme.screenBackground

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.date = selectedDay
        datePicker.maximumDate = Date()
        datePicker.tintColor = AppTheme.accent
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addAction(
            UIAction { [weak self, weak datePicker] _ in
                guard let date = datePicker?.date else {
                    return
                }

                self?.selectDay(date)
            },
            for: .valueChanged
        )

        pickerViewController.view.addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: pickerViewController.view.safeAreaLayoutGuide.topAnchor, constant: 12),
            datePicker.leadingAnchor.constraint(equalTo: pickerViewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: pickerViewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])

        pickerViewController.modalPresentationStyle = .pageSheet
        if let sheetPresentationController = pickerViewController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.selectedDetentIdentifier = .medium
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 18
        }

        present(pickerViewController, animated: true)
    }

    private func selectDay(_ day: Date) {
        let calendar = Calendar.current
        let requestedDay = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())
        selectedDay = min(requestedDay, today)
        loadActivities()
    }

    private func selectRelativeDay(offset: Int) {
        guard let day = Calendar.current.date(
            byAdding: .day,
            value: offset,
            to: selectedDay
        ) else {
            return
        }

        selectDay(day)
    }

    private func isSelectedDayToday() -> Bool {
        Calendar.current.isDateInToday(selectedDay)
    }

    @objc private func activityDidPersist() {
        loadActivities()
    }

    @objc private func activeTimersDidChange() {
        loadActivities()
    }

    @objc private func durationDisplayDidChange() {
        loadActivities()
    }
}

extension SummarizeMyDayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activityRows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DaySummaryCell.reuseIdentifier,
            for: indexPath
        ) as? DaySummaryCell
        cell?.configure(with: activityRows[indexPath.row])
        return cell ?? UITableViewCell()
    }
}

extension SummarizeMyDayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard case let .completed(activity) = activityRows[indexPath.row].source else {
            return
        }

        showActivityDetails(for: activity)
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
