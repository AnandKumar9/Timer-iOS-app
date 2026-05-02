import UIKit
import SwiftData

final class ActivityTypesViewController: UIViewController {
    private struct ActivityTypeRow {
        let activityType: ActivityType
        let name: String
        let latestActivityStartTime: Date?
    }

    private final class ActivityTypeCell: UITableViewCell {
        static let reuseIdentifier = "ActivityTypeCell"

        var onStartTapped: (() -> Void)?

        private let nameLabel = UILabel()
        private let latestActivityLabel = UILabel()

        private lazy var startButton: UIButton = {
            var configuration = UIButton.Configuration.filled()
            configuration.title = "Record New"
            configuration.buttonSize = .small
            configuration.cornerStyle = .fixed
            configuration.baseBackgroundColor = .systemBlue
            configuration.baseForegroundColor = .white
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)

            let button = UIButton(configuration: configuration)
            button.layer.cornerRadius = 6
            button.clipsToBounds = true
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.addAction(
                UIAction { [weak self] _ in
                    self?.onStartTapped?()
                },
                for: .touchUpInside
            )
            return button
        }()

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
        }

        func configure(with row: ActivityTypeRow, dateFormatter: DateFormatter) {
            nameLabel.text = row.name

            if let latestActivityStartTime = row.latestActivityStartTime {
                latestActivityLabel.text = "Latest: \(dateFormatter.string(from: latestActivityStartTime))"
            } else {
                latestActivityLabel.text = "No activity recorded"
            }
        }

        private func configureCell() {
            nameLabel.font = .systemFont(ofSize: 17, weight: .regular)
            nameLabel.textColor = .label
            nameLabel.numberOfLines = 1

            latestActivityLabel.font = .systemFont(ofSize: 14, weight: .regular)
            latestActivityLabel.textColor = .secondaryLabel
            latestActivityLabel.numberOfLines = 1

            let labelStackView = UIStackView(arrangedSubviews: [nameLabel, latestActivityLabel])
            labelStackView.axis = .vertical
            labelStackView.alignment = .fill
            labelStackView.spacing = 4
            labelStackView.translatesAutoresizingMaskIntoConstraints = false

            startButton.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(labelStackView)
            contentView.addSubview(startButton)

            NSLayoutConstraint.activate([
                labelStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                labelStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                labelStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
                labelStackView.trailingAnchor.constraint(lessThanOrEqualTo: startButton.leadingAnchor, constant: -16),

                startButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                startButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
            ])
        }
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()
    private let currentTimersButton = UIButton(type: .system)
    private var activityTypeRows: [ActivityTypeRow] = []
    private var didPromptForInitialActivityTypeCreation = false

    var modelContext: ModelContext?

    private lazy var latestActivityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        loadActivityTypes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadActivityTypes()
        updateCurrentTimersButtonVisibility()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.addButtonTapped()
            }
        )

        view.backgroundColor = .systemBackground

        configureTableView()
        configureEmptyStateLabel()
        configureCurrentTimersButton()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimersButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(currentTimersButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            currentTimersButton.widthAnchor.constraint(equalToConstant: 56),
            currentTimersButton.heightAnchor.constraint(equalToConstant: 56),
            currentTimersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            currentTimersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
        emptyStateLabel.font = .systemFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
    }

    private func configureCurrentTimersButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "timer")
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white

        currentTimersButton.configuration = configuration
        currentTimersButton.layer.cornerRadius = 18
        currentTimersButton.layer.cornerCurve = .continuous
        currentTimersButton.clipsToBounds = true
        currentTimersButton.layer.shadowColor = UIColor.black.cgColor
        currentTimersButton.layer.shadowOpacity = 0.18
        currentTimersButton.layer.shadowRadius = 10
        currentTimersButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        currentTimersButton.isHidden = !TimerSessionState.hasStartedTimer
        currentTimersButton.addAction(
            UIAction { [weak self] _ in
                self?.showTimerViewController()
            },
            for: .touchUpInside
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerSessionDidStartTimer),
            name: TimerSessionState.didStartTimerNotification,
            object: nil
        )
    }

    private func loadActivityTypes() {
        guard let modelContext else {
            activityTypeRows = []
            updateContent()
            return
        }

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            activityTypeRows = activityTypes
                .map(makeActivityTypeRow)
                .sorted(by: activityTypeSort)
            updateContent()
        } catch {
            assertionFailure("Unable to load activity types: \(error)")
        }
    }

    private func makeActivityTypeRow(from activityType: ActivityType) -> ActivityTypeRow {
        ActivityTypeRow(
            activityType: activityType,
            name: activityType.name,
            latestActivityStartTime: activityType.activities.compactMap(\.activityStartTime).max()
        )
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
        emptyStateLabel.isHidden = !activityTypeRows.isEmpty
    }

    private func promptForInitialActivityTypeIfNeeded() {
        guard !didPromptForInitialActivityTypeCreation else {
            return
        }

        guard activityTypeRows.isEmpty else {
            return
        }

        didPromptForInitialActivityTypeCreation = true
        presentCreateActivityTypeAlert()
    }

    @objc private func timerSessionDidStartTimer() {
        updateCurrentTimersButtonVisibility()
    }

    private func updateCurrentTimersButtonVisibility() {
        currentTimersButton.isHidden = !TimerSessionState.hasStartedTimer
    }

    private func startActivityType(_ activityType: ActivityType) {
        presentTimerViewController(modelContext: modelContext, activityType: activityType)
    }

    private func showTimerViewController(activityType: ActivityType? = nil) {
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
        guard let modelContext else {
            return
        }

        modelContext.delete(activityType)
        try modelContext.save()
        loadActivityTypes()
    }

    private func addButtonTapped() {
        presentCreateActivityTypeAlert()
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
        cell?.configure(with: row, dateFormatter: latestActivityDateFormatter)
        cell?.onStartTapped = { [weak self] in
            self?.startActivityType(row.activityType)
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
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        makeDeleteSwipeActionsConfiguration(for: indexPath)
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
            do {
                try self?.deleteActivityType(row.activityType)
                completion(true)
            } catch {
                assertionFailure("Unable to delete activity type: \(error)")
                completion(false)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
