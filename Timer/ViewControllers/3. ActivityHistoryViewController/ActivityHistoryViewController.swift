import UIKit
import SwiftData

final class ActivityHistoryViewController: UIViewController {
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
            activitySummaryLabel.attributedText = makeActivitySummaryText(
                dateText: row.doneTimeText,
                durationText: row.durationText
            )
        }

        private func configureCell() {
            selectionStyle = .none

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
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.label
                ]
            )

            let durationRange = (summaryText as NSString).range(of: durationText)
            attributedText.addAttributes(
                [.font: UIFont.systemFont(ofSize: 20, weight: .semibold)],
                range: durationRange
            )

            return attributedText
        }
    }

    private struct ActivityHistoryRow {
        let activity: Activity
        let doneTimeText: String
        let durationText: String
    }

    private let activityNameLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()
    private var activityRows: [ActivityHistoryRow] = []

    var modelContext: ModelContext?
    var activityType: ActivityType?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        loadActivities()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadActivities()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAppearance() {
        title = "Activity History"
        view.backgroundColor = .systemBackground

        configureActivityNameLabel()
        configureTableView()
        configureEmptyStateLabel()
        configureActivityNotifications()

        activityNameLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityNameLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            activityNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            activityNameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            activityNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: activityNameLabel.bottomAnchor, constant: 24),
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
        activityNameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        activityNameLabel.textColor = .label
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

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.register(ActivityHistoryCell.self, forCellReuseIdentifier: ActivityHistoryCell.reuseIdentifier)
    }

    private func configureEmptyStateLabel() {
        emptyStateLabel.text = "No completed activities"
        emptyStateLabel.font = .systemFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
    }

    private func configureActivityNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activityDidPersist(_:)),
            name: TimerSessionState.didPersistActivityNotification,
            object: nil
        )
    }

    private func loadActivities() {
        activityNameLabel.text = activityType?.name ?? "Activity"

        guard let activityType else {
            activityRows = []
            updateContent()
            return
        }

        activityRows = activityType.activities
            .filter { $0.activityCompletionTime != nil }
            .sorted { lhs, rhs in
                guard let lhsCompletionTime = lhs.activityCompletionTime else {
                    return false
                }

                guard let rhsCompletionTime = rhs.activityCompletionTime else {
                    return true
                }

                return lhsCompletionTime > rhsCompletionTime
            }
            .compactMap(makeActivityHistoryRow)
        updateContent()
    }

    private func makeActivityHistoryRow(from activity: Activity) -> ActivityHistoryRow? {
        guard let completionTime = activity.activityCompletionTime else {
            return nil
        }

        return ActivityHistoryRow(
            activity: activity,
            doneTimeText: activityHistoryDateText(for: completionTime),
            durationText: makeDurationText(for: activity, completionTime: completionTime)
        )
    }

    private func activityHistoryDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM dd (EEE)  hh:mm a"
        return formatter.string(from: date)
    }

    private func makeDurationText(for activity: Activity, completionTime: Date) -> String {
        if let timeTaken = activity.timeTaken {
            return ActivityDisplayFormatter.roundedHistoryDurationText(for: timeTaken)
        }

        guard let startTime = activity.activityStartTime else {
            return "Unavailable"
        }

        return ActivityDisplayFormatter.roundedHistoryDurationText(
            for: completionTime.timeIntervalSince(startTime)
        )
    }

    private func presentDeleteActivityAlert(for row: ActivityHistoryRow, completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(
            title: "Delete Activity?",
            message: "Delete \(row.doneTimeText) : \(row.durationText)?",
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

    @objc private func activityNameLabelTapped() {
        guard activityType != nil else {
            return
        }

        presentRenameActivityTypeAlert()
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
