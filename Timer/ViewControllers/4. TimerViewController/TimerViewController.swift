import UIKit

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
    private let historyRows = [
        TimerHistoryRow(dateText: "05/02 (09:15 AM)", durationText: "1 hr 20 min"),
        TimerHistoryRow(dateText: "05/01 (06:40 PM)", durationText: "45 min"),
        TimerHistoryRow(dateText: "04/30 (07:10 AM)", durationText: "2 hr 5 min"),
        TimerHistoryRow(dateText: "04/29 (08:30 PM)", durationText: "30 min"),
        TimerHistoryRow(dateText: "04/28 (12:05 PM)", durationText: "1 hr 0 min"),
        TimerHistoryRow(dateText: "04/27 (03:45 PM)", durationText: "3 hr 15 min"),
        TimerHistoryRow(dateText: "04/26 (10:20 AM)", durationText: "55 min"),
        TimerHistoryRow(dateText: "04/25 (05:35 PM)", durationText: "1 hr 40 min"),
        TimerHistoryRow(dateText: "04/24 (11:50 AM)", durationText: "2 hr 25 min"),
        TimerHistoryRow(dateText: "04/23 (09:05 PM)", durationText: "20 min")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
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
