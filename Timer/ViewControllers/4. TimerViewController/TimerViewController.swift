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

    private let timerControlsView = TimerControlsView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var historyRows: [TimerHistoryRow] = []
    private let activityTypeName = "Timer"
    private var didCheckForInitialActivityType = false
    private var existingActivityTypeNames: Set<String> = []
    private weak var createActivityTypeAction: UIAlertAction?

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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkForInitialActivityType()
    }

    private func configureAppearance() {
        view.backgroundColor = .systemBackground

        configureTableView()

        timerControlsView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(timerControlsView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            timerControlsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96),
            timerControlsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            timerControlsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: timerControlsView.bottomAnchor, constant: 32),
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
        timerControlsView.onTimerStopped = { [weak self] startTime, completionTime in
            self?.saveTimerActivity(startTime: startTime, completionTime: completionTime)
        }
    }

    private func checkForInitialActivityType() {
        guard !didCheckForInitialActivityType else {
            return
        }

        didCheckForInitialActivityType = true

        guard let modelContext else {
            return
        }

        var descriptor = FetchDescriptor<ActivityType>()
        descriptor.fetchLimit = 1

        do {
            let activityTypes = try modelContext.fetch(descriptor)
            if activityTypes.isEmpty {
                presentCreateActivityTypeAlert()
            }
        } catch {
            assertionFailure("Unable to check activity types: \(error)")
        }
    }

    private func presentCreateActivityTypeAlert() {
        existingActivityTypeNames = fetchExistingActivityTypeNames()

        let alertController = UIAlertController(
            title: "New Activity",
            message: "Enter an activity name.",
            preferredStyle: .alert
        )

        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Activity name"
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.addTarget(
                self,
                action: #selector(TimerViewController.activityTypeNameChanged(_:)),
                for: .editingChanged
            )
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak alertController] _ in
            guard let activityName = alertController?.textFields?.first?.text else {
                return
            }

            self?.createActivityType(named: activityName)
        }
        submitAction.isEnabled = false
        createActivityTypeAction = submitAction

        alertController.addAction(submitAction)
        present(alertController, animated: true)
    }

    @objc private func activityTypeNameChanged(_ textField: UITextField) {
        createActivityTypeAction?.isEnabled = isUniqueActivityTypeName(textField.text)
    }

    private func isUniqueActivityTypeName(_ name: String?) -> Bool {
        let normalizedName = normalizeActivityTypeName(name)
        return !normalizedName.isEmpty && !existingActivityTypeNames.contains(normalizedName)
    }

    private func createActivityType(named name: String) {
        guard let modelContext else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isUniqueActivityTypeName(trimmedName) else {
            presentCreateActivityTypeAlert()
            return
        }

        let activityType = ActivityType(activityName: trimmedName)
        modelContext.insert(activityType)

        do {
            try modelContext.save()
            existingActivityTypeNames.insert(normalizeActivityTypeName(trimmedName))
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
            return Set(activityTypes.map { normalizeActivityTypeName($0.activityName) })
        } catch {
            assertionFailure("Unable to fetch activity type names: \(error)")
            return []
        }
    }

    private func normalizeActivityTypeName(_ name: String?) -> String {
        name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedLowercase ?? ""
    }

    private func saveTimerActivity(startTime: Date, completionTime: Date) {
        guard let modelContext else {
            return
        }

        guard let activityType = fetchTimerActivityType(in: modelContext) else {
            return
        }

        let activity = Activity(
            activityType: activityType,
            actvityStartTime: startTime,
            activityCompletionTime: completionTime
        )

        modelContext.insert(activity)

        do {
            try modelContext.save()
            loadTimerHistory()
        } catch {
            modelContext.delete(activity)
            assertionFailure("Unable to save timer activity: \(error)")
        }
    }

    private func fetchTimerActivityType(in modelContext: ModelContext) -> ActivityType? {
        let activityTypeName = self.activityTypeName
        let descriptor = FetchDescriptor<ActivityType>(
            predicate: #Predicate { $0.activityName == activityTypeName }
        )

        return try? modelContext.fetch(descriptor).first
    }

    private func loadTimerHistory() {
        guard let modelContext else {
            historyRows = []
            tableView.reloadData()
            return
        }

        var descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { $0.activityCompletionTime != nil },
            sortBy: [SortDescriptor(\.actvityStartTime, order: .reverse)]
        )
        descriptor.fetchLimit = 50

        do {
            let activities = try modelContext.fetch(descriptor)
            historyRows = activities.compactMap(makeHistoryRow)
            tableView.reloadData()
        } catch {
            assertionFailure("Unable to load timer history: \(error)")
        }
    }

    private func makeHistoryRow(from activity: Activity) -> TimerHistoryRow? {
        guard let completionTime = activity.activityCompletionTime else {
            return nil
        }

        return TimerHistoryRow(
            dateText: historyDateFormatter.string(from: activity.actvityStartTime),
            durationText: formattedDuration(from: activity.actvityStartTime, to: completionTime)
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
