import UIKit
import SwiftData

final class TimerViewController: UIViewController {
    private final class TimerHistoryCell: UITableViewCell {
        static let reuseIdentifier = "TimerHistoryCell"

        private let dateLabel = UILabel()
        private let durationLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: TimerHistoryRow) {
            dateLabel.text = row.dateText
            durationLabel.text = row.durationText
        }

        private func configureCell() {
            selectionStyle = .none

            dateLabel.font = .systemFont(ofSize: 16, weight: .regular)
            dateLabel.textColor = .label
            dateLabel.textAlignment = .left

            durationLabel.font = .systemFont(ofSize: 16, weight: .regular)
            durationLabel.textColor = .secondaryLabel
            durationLabel.textAlignment = .right
            durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let stackView = UIStackView(arrangedSubviews: [dateLabel, durationLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    private struct TimerHistoryRow {
        let dateText: String
        let durationText: String
    }

    private let timerControlsContainerView = UIView()
    private weak var timerControlsView: TimerControlsView?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var historyRows: [TimerHistoryRow] = []
    private var didPromptForInitialActivityType = false
    private var initialActivityType: ActivityType?

    var modelContext: ModelContext?

    private lazy var historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (hh:mm a)"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureTimerPersistence()
        loadTimerHistory()

        if let initialActivityType {
            didPromptForInitialActivityType = true
            installTimerControlsView(activityType: initialActivityType)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        promptForInitialActivityTypeIfNeeded()
    }

    private func configureAppearance() {
        title = "Timers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Activity Types",
            style: .plain,
            target: self,
            action: #selector(activityTypesButtonTapped)
        )

        view.backgroundColor = .systemBackground

        configureTableView()

        timerControlsContainerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(timerControlsContainerView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            timerControlsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96),
            timerControlsContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            timerControlsContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: timerControlsContainerView.bottomAnchor, constant: 32),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.register(TimerHistoryCell.self, forCellReuseIdentifier: TimerHistoryCell.reuseIdentifier)
    }

    private func configureTimerPersistence() {
    }

    func configure(activityType: ActivityType) {
        initialActivityType = activityType
    }

    @objc private func activityTypesButtonTapped() {
        let activityTypesViewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        activityTypesViewController.modelContext = modelContext
        navigationController?.pushViewController(activityTypesViewController, animated: true)
    }

    private func makeTimerActivity(activityType: ActivityType) -> Activity {
        return Activity(activityType: activityType)
    }

    private func installTimerControlsView(activityType: ActivityType) {
        timerControlsView?.removeFromSuperview()

        let activity = makeTimerActivity(activityType: activityType)
        let timerControlsView = TimerControlsView(activity: activity)
        timerControlsView.translatesAutoresizingMaskIntoConstraints = false
        timerControlsView.onActivityStopped = { [weak self] activity in
            self?.saveTimerActivity(activity)
        }

        timerControlsContainerView.addSubview(timerControlsView)

        NSLayoutConstraint.activate([
            timerControlsView.topAnchor.constraint(equalTo: timerControlsContainerView.topAnchor),
            timerControlsView.leadingAnchor.constraint(equalTo: timerControlsContainerView.leadingAnchor),
            timerControlsView.trailingAnchor.constraint(equalTo: timerControlsContainerView.trailingAnchor),
            timerControlsView.bottomAnchor.constraint(equalTo: timerControlsContainerView.bottomAnchor)
        ])

        self.timerControlsView = timerControlsView
    }

    private func promptForInitialActivityTypeIfNeeded() {
        guard !didPromptForInitialActivityType else {
            return
        }

        didPromptForInitialActivityType = true

        guard timerControlsView == nil else {
            return
        }

        guard let modelContext else {
            return
        }

        var descriptor = FetchDescriptor<ActivityType>()
        descriptor.fetchLimit = 1

        do {
            if try modelContext.fetch(descriptor).isEmpty {
                presentCreateActivityTypeAlert()
            }
        } catch {
            assertionFailure("Unable to check activity types: \(error)")
        }
    }

    private func presentCreateActivityTypeAlert() {
        let existingNames = fetchExistingActivityTypeNames()
        let alertController = UIAlertController(
            title: "New Activity Type",
            message: "Enter an activity type name.",
            preferredStyle: .alert
        )

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let name = alertController?.textFields?.first?.text else {
                return
            }

            self?.createInitialActivityType(named: name)
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

        alertController.addAction(submitAction)
        present(alertController, animated: true)
    }

    private func createInitialActivityType(named name: String) {
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
            installTimerControlsView(activityType: activityType)
        } catch {
            modelContext.delete(activityType)
            assertionFailure("Unable to save activity type: \(error)")
            presentCreateActivityTypeAlert()
        }
    }

    private func fetchExistingActivityTypeNames() -> Set<String> {
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

    private func saveTimerActivity(_ activity: Activity) {
        guard let modelContext else {
            return
        }

        guard activity.activityStartTime != nil else {
            return
        }

        if !activity.activityType.activities.contains(where: { $0 === activity }) {
            activity.activityType.activities.append(activity)
        }

        modelContext.insert(activity)

        do {
            try modelContext.save()
            loadTimerHistory()
            installTimerControlsView(activityType: activity.activityType)
        } catch {
            modelContext.delete(activity)
            assertionFailure("Unable to save timer activity: \(error)")
        }
    }

    private func loadTimerHistory() {
        guard let modelContext else {
            historyRows = []
            tableView.reloadData()
            return
        }

        var descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { $0.activityCompletionTime != nil }
        )
        descriptor.fetchLimit = 50

        do {
            let activities = try modelContext.fetch(descriptor)
            historyRows = activities
                .sorted { lhs, rhs in
                    guard let lhsStartTime = lhs.activityStartTime else {
                        return false
                    }

                    guard let rhsStartTime = rhs.activityStartTime else {
                        return true
                    }

                    return lhsStartTime > rhsStartTime
                }
                .compactMap(makeHistoryRow)
            tableView.reloadData()
        } catch {
            assertionFailure("Unable to load timer history: \(error)")
        }
    }

    private func makeHistoryRow(from activity: Activity) -> TimerHistoryRow? {
        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return nil
        }

        return TimerHistoryRow(
            dateText: historyDateFormatter.string(from: startTime),
            durationText: formattedDuration(from: startTime, to: completionTime)
        )
    }

    private func formattedDuration(from startTime: Date, to completionTime: Date) -> String {
        let duration = max(0, Int(completionTime.timeIntervalSince(startTime)))
        let hours = duration / 3_600
        let minutes = (duration % 3_600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
        }
    }
}

extension TimerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        historyRows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TimerHistoryCell.reuseIdentifier,
            for: indexPath
        ) as? TimerHistoryCell
        let row = historyRows[indexPath.row]
        cell?.configure(with: row)
        return cell ?? UITableViewCell()
    }
}
