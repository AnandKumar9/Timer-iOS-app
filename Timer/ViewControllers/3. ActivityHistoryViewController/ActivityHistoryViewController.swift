import UIKit
import SwiftData

final class ActivityHistoryViewController: UIViewController {
    private final class ActivityHistoryCell: UITableViewCell {
        static let reuseIdentifier = "ActivityHistoryCell"

        private let doneTimeLabel = UILabel()
        private let durationLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: ActivityHistoryRow) {
            doneTimeLabel.text = row.doneTimeText
            durationLabel.text = row.durationText
        }

        private func configureCell() {
            selectionStyle = .none

            doneTimeLabel.font = .systemFont(ofSize: 16, weight: .regular)
            doneTimeLabel.textColor = .label
            doneTimeLabel.numberOfLines = 1

            durationLabel.font = .systemFont(ofSize: 16, weight: .medium)
            durationLabel.textColor = .secondaryLabel
            durationLabel.textAlignment = .right
            durationLabel.numberOfLines = 1
            durationLabel.setContentHuggingPriority(.required, for: .horizontal)
            durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let stackView = UIStackView(arrangedSubviews: [doneTimeLabel, durationLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
            ])
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
    private let currentTimersButton = UIButton(type: .system)
    private var activityRows: [ActivityHistoryRow] = []

    var modelContext: ModelContext?
    var activityType: ActivityType?

    private lazy var doneTimeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        loadActivities()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadActivities()
        updateCurrentTimersButtonVisibility()
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
        configureCurrentTimersButton()

        activityNameLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimersButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityNameLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(currentTimersButton)

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
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            currentTimersButton.widthAnchor.constraint(equalToConstant: 56),
            currentTimersButton.heightAnchor.constraint(equalToConstant: 56),
            currentTimersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            currentTimersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func configureActivityNameLabel() {
        activityNameLabel.text = activityType?.name ?? "Activity"
        activityNameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        activityNameLabel.textColor = .label
        activityNameLabel.numberOfLines = 0
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
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

    private func configureCurrentTimersButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "timer")
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white

        currentTimersButton.configuration = configuration
        currentTimersButton.layer.cornerRadius = 18
        currentTimersButton.layer.cornerCurve = .continuous
        currentTimersButton.clipsToBounds = true
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
            doneTimeText: doneTimeDateFormatter.string(from: completionTime),
            durationText: makeDurationText(for: activity, completionTime: completionTime)
        )
    }

    private func makeDurationText(for activity: Activity, completionTime: Date) -> String {
        guard let startTime = activity.activityStartTime else {
            return "Start time unavailable"
        }

        return formattedDuration(from: startTime, to: completionTime)
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

    private func updateContent() {
        tableView.reloadData()
        emptyStateLabel.isHidden = !activityRows.isEmpty
    }

    @objc private func timerSessionDidStartTimer() {
        updateCurrentTimersButtonVisibility()
    }

    private func updateCurrentTimersButtonVisibility() {
        currentTimersButton.isHidden = !TimerSessionState.hasStartedTimer
    }

    private func showActivityDetails(for activity: Activity) {
        let activityDetailsViewController = ActivityDetailsViewController(
            nibName: "ActivityDetailsViewController",
            bundle: nil
        )
        activityDetailsViewController.modelContext = modelContext
        navigationController?.pushViewController(activityDetailsViewController, animated: true)
    }

    private func showTimerViewController() {
        presentTimerViewController(modelContext: modelContext)
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

extension ActivityHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        showActivityDetails(for: activityRows[indexPath.row].activity)
    }
}
