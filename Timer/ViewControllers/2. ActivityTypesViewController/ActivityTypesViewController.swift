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
            configuration.title = "Start"
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
    private var activityTypeRows: [ActivityTypeRow] = []

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
    }

    private func configureAppearance() {
        title = "Activity Types"
        view.backgroundColor = .systemBackground

        configureTableView()
        configureEmptyStateLabel()

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
        emptyStateLabel.font = .systemFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
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

    private func startActivityType(_ activityType: ActivityType) {
        let timerViewController = TimerViewController(
            nibName: "TimerViewController",
            bundle: nil
        )
        timerViewController.modelContext = modelContext
        timerViewController.configure(activityType: activityType)
        navigationController?.pushViewController(timerViewController, animated: true)
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
