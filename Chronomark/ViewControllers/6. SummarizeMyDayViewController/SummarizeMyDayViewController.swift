import UIKit
import SwiftData

final class SummarizeMyDayViewController: UIViewController {
    private static let earlyTodayEmptyStateText = "Your day has just started"
    private static let emptyStateQuotes = [
        "How we spend our days is, of course, how we spend our lives.",
        "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
        "First we make our habits, then our habits make us.",
        "Motivation is what gets you started. Habit is what keeps you going.",
        "The secret of your future is hidden in your daily routine.",
        "A schedule defends from chaos and whim.",
        "Success is nothing more than a few simple disciplines, practiced every day.",
        "Men’s natures are alike; it is their habits that separate them.",
        "I always wanted to be somebody, but now I realize I should have been more specific.",
        "My routine is basically just trying to remember why I walked into a room.",
        "The road to success is dotted with many tempting parking spaces.",
        "If at first you don’t succeed, then skydiving definitely isn’t for you.",
        "A day without sunshine is like, you know, night.",
        "My life has a superb cast, but I can’t figure out the plot.",
        "My favorite exercise is a cross between a lunge and a crunch. I call it lunch.",
        "I used to think I was indecisive, but now I’m not sure.",
        "My patience is like Wi-Fi — weak when too many people are connected.",
        "I’m on energy-saving mode.",
        "Adulting is just googling how to do stuff.",
        "I’m silently correcting your grammar.",
        "I’m not lazy. I’m on power-saving mode.",
        "Too old for TikTok, too young for Facebook.",
        "Some people graduate with honors, I am just honored to graduate.",
        "I’m not arguing. I’m just explaining why I’m right.",
        "Reality called, so I hung up.",
        "I came. I saw. I forgot what I was doing.",
    ]

    private final class DaySummaryCell: UITableViewCell {
        static let reuseIdentifier = "DaySummaryCell"
        private static let maximumVisibleTagCount = 3

        private final class PillLabel: UILabel {
            private let contentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

            override var intrinsicContentSize: CGSize {
                let baseSize = super.intrinsicContentSize
                return CGSize(
                    width: baseSize.width + contentInsets.left + contentInsets.right,
                    height: baseSize.height + contentInsets.top + contentInsets.bottom
                )
            }

            override func drawText(in rect: CGRect) {
                super.drawText(in: rect.inset(by: contentInsets))
            }
        }

        private let timeLabel = UILabel()
        private let activityNameLabel = UILabel()
        private let statusImageView = UIImageView()
        private let durationLabel = UILabel()
        private let noteLabel = UILabel()
        private let tagPreviewContainerView = UIView()
        private let tagPreviewStackView = UIStackView()

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
            configureTagPreviews(row.tagTexts)

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

            tagPreviewContainerView.clipsToBounds = true

            tagPreviewStackView.axis = .horizontal
            tagPreviewStackView.alignment = .center
            tagPreviewStackView.spacing = 6
            tagPreviewStackView.translatesAutoresizingMaskIntoConstraints = false

            tagPreviewContainerView.addSubview(tagPreviewStackView)

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

            let detailStackView = UIStackView(arrangedSubviews: [titleStackView, noteLabel, tagPreviewContainerView])
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
                tagPreviewStackView.leadingAnchor.constraint(equalTo: tagPreviewContainerView.leadingAnchor),
                tagPreviewStackView.topAnchor.constraint(equalTo: tagPreviewContainerView.topAnchor),
                tagPreviewStackView.bottomAnchor.constraint(equalTo: tagPreviewContainerView.bottomAnchor),
                tagPreviewStackView.trailingAnchor.constraint(lessThanOrEqualTo: tagPreviewContainerView.trailingAnchor),

                rowStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                rowStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                rowStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
                rowStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
            ])
        }

        private func configureTagPreviews(_ tags: [String]) {
            tagPreviewStackView.arrangedSubviews.forEach { view in
                tagPreviewStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            tagPreviewContainerView.isHidden = tags.isEmpty

            let visibleTags = Array(tags.prefix(Self.maximumVisibleTagCount))
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

    private final class ActivityTypeSummaryCell: UITableViewCell {
        static let reuseIdentifier = "ActivityTypeSummaryCell"

        private let nameLabel = UILabel()
        private let durationLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureCell()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureCell()
        }

        func configure(with row: ActivityTypeSummaryRow) {
            configure(name: row.activityTypeName, durationText: row.durationText)
        }

        func configure(with row: ActivityTagSummaryRow) {
            configure(name: row.tagName, durationText: row.durationText)
        }

        private func configure(name: String, durationText: String) {
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground

            nameLabel.text = name
            nameLabel.textColor = AppTheme.primaryText
            durationLabel.text = durationText
            durationLabel.textColor = AppTheme.durationText
        }

        private func configureCell() {
            backgroundColor = AppTheme.screenBackground
            selectedBackgroundView = UIView()
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground
            contentView.backgroundColor = AppTheme.screenBackground

            nameLabel.font = AppTheme.roundedFont(ofSize: 16, weight: .semibold)
            nameLabel.numberOfLines = 1
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.8

            durationLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .semibold)
            durationLabel.numberOfLines = 1
            durationLabel.textAlignment = .right
            durationLabel.setContentHuggingPriority(.required, for: .horizontal)
            durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let rowStackView = UIStackView(arrangedSubviews: [nameLabel, durationLabel])
            rowStackView.axis = .horizontal
            rowStackView.alignment = .center
            rowStackView.spacing = 12
            rowStackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(rowStackView)

            NSLayoutConstraint.activate([
                rowStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                rowStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                rowStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                rowStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
            ])
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
        let tagTexts: [String]
    }

    private struct ActivityTypeSummaryRow {
        let activityTypeID: UUID
        let activityTypeName: String
        let totalDuration: TimeInterval

        var durationText: String {
            ActivityDisplayFormatter.roundedHistoryDurationText(for: totalDuration)
        }
    }

    private struct ActivityTagSummaryRow {
        let tagID: UUID
        let tagName: String
        let totalDuration: TimeInterval

        var durationText: String {
            ActivityDisplayFormatter.roundedHistoryDurationText(for: totalDuration)
        }
    }

    private let tagSummarySectionTitleLabel = UILabel()
    private let activityTagSummaryTableView = UITableView(frame: .zero, style: .plain)
    private let summarySectionTitleLabel = UILabel()
    private let activityTypeSummaryTableView = UITableView(frame: .zero, style: .plain)
    private let activitiesSectionTitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerStackView = UIStackView()
    private let previousDayButton = UIButton(type: .system)
    private let summaryLabel = UILabel()
    private let dayPickerButton = UIButton(type: .system)
    private let nextDayButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    private var activityRows: [DaySummaryRow] = []
    private var activityTagSummaryRows: [ActivityTagSummaryRow] = []
    private var activityTypeSummaryRows: [ActivityTypeSummaryRow] = []
    private var activityTagSummaryTableHeightConstraint: NSLayoutConstraint?
    private var activityTypeSummaryTableHeightConstraint: NSLayoutConstraint?
    private var activityTypeSectionTopToTagConstraint: NSLayoutConstraint?
    private var activityTypeSectionTopToHeaderConstraint: NSLayoutConstraint?
    private var activitiesSectionTopToSummaryConstraint: NSLayoutConstraint?
    private var activitiesSectionTopToTagConstraint: NSLayoutConstraint?
    private var activitiesSectionTopToHeaderConstraint: NSLayoutConstraint?
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
        configureTagSummarySectionTitleLabel()
        configureActivityTagSummaryTableView()
        configureSummarySectionTitleLabel()
        configureActivityTypeSummaryTableView()
        configureActivitiesSectionTitleLabel()
        configureTableView()
        configureEmptyStateLabel()
        applyTheme()

        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        tagSummarySectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        activityTagSummaryTableView.translatesAutoresizingMaskIntoConstraints = false
        summarySectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        activityTypeSummaryTableView.translatesAutoresizingMaskIntoConstraints = false
        activitiesSectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStackView)
        view.addSubview(tagSummarySectionTitleLabel)
        view.addSubview(activityTagSummaryTableView)
        view.addSubview(summarySectionTitleLabel)
        view.addSubview(activityTypeSummaryTableView)
        view.addSubview(activitiesSectionTitleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        let activityTagSummaryTableHeightConstraint = activityTagSummaryTableView.heightAnchor.constraint(equalToConstant: 0)
        let activityTypeSummaryTableHeightConstraint = activityTypeSummaryTableView.heightAnchor.constraint(equalToConstant: 0)
        self.activityTagSummaryTableHeightConstraint = activityTagSummaryTableHeightConstraint
        self.activityTypeSummaryTableHeightConstraint = activityTypeSummaryTableHeightConstraint
        let activityTypeSectionTopToTagConstraint = summarySectionTitleLabel.topAnchor.constraint(
            equalTo: activityTagSummaryTableView.bottomAnchor,
            constant: 32
        )
        let activityTypeSectionTopToHeaderConstraint = summarySectionTitleLabel.topAnchor.constraint(
            equalTo: headerStackView.bottomAnchor,
            constant: 18
        )
        let activitiesSectionTopToSummaryConstraint = activitiesSectionTitleLabel.topAnchor.constraint(
            equalTo: activityTypeSummaryTableView.bottomAnchor,
            constant: 32
        )
        let activitiesSectionTopToTagConstraint = activitiesSectionTitleLabel.topAnchor.constraint(
            equalTo: activityTagSummaryTableView.bottomAnchor,
            constant: 32
        )
        let activitiesSectionTopToHeaderConstraint = activitiesSectionTitleLabel.topAnchor.constraint(
            equalTo: headerStackView.bottomAnchor,
            constant: 28
        )
        self.activityTypeSectionTopToTagConstraint = activityTypeSectionTopToTagConstraint
        self.activityTypeSectionTopToHeaderConstraint = activityTypeSectionTopToHeaderConstraint
        self.activitiesSectionTopToSummaryConstraint = activitiesSectionTopToSummaryConstraint
        self.activitiesSectionTopToTagConstraint = activitiesSectionTopToTagConstraint
        self.activitiesSectionTopToHeaderConstraint = activitiesSectionTopToHeaderConstraint

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            headerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tagSummarySectionTitleLabel.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 18),
            tagSummarySectionTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            tagSummarySectionTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            activityTagSummaryTableView.topAnchor.constraint(equalTo: tagSummarySectionTitleLabel.bottomAnchor, constant: 8),
            activityTagSummaryTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            activityTagSummaryTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            activityTagSummaryTableHeightConstraint,

            activityTypeSectionTopToHeaderConstraint,
            summarySectionTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            summarySectionTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            activityTypeSummaryTableView.topAnchor.constraint(equalTo: summarySectionTitleLabel.bottomAnchor, constant: 8),
            activityTypeSummaryTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            activityTypeSummaryTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            activityTypeSummaryTableHeightConstraint,

            activitiesSectionTopToSummaryConstraint,
            activitiesSectionTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            activitiesSectionTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: activitiesSectionTitleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 48),
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

    private func configureTagSummarySectionTitleLabel() {
        tagSummarySectionTitleLabel.text = "Activity tag totals"
        tagSummarySectionTitleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        tagSummarySectionTitleLabel.textColor = AppTheme.metadataText
        tagSummarySectionTitleLabel.numberOfLines = 1
    }

    private func configureActivityTagSummaryTableView() {
        activityTagSummaryTableView.dataSource = self
        activityTagSummaryTableView.delegate = self
        activityTagSummaryTableView.rowHeight = UITableView.automaticDimension
        activityTagSummaryTableView.estimatedRowHeight = 48
        activityTagSummaryTableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        activityTagSummaryTableView.register(
            ActivityTypeSummaryCell.self,
            forCellReuseIdentifier: ActivityTypeSummaryCell.reuseIdentifier
        )
    }

    private func configureSummarySectionTitleLabel() {
        summarySectionTitleLabel.text = "Activity type totals"
        summarySectionTitleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        summarySectionTitleLabel.textColor = AppTheme.metadataText
        summarySectionTitleLabel.numberOfLines = 1
    }

    private func configureActivityTypeSummaryTableView() {
        activityTypeSummaryTableView.dataSource = self
        activityTypeSummaryTableView.delegate = self
        activityTypeSummaryTableView.rowHeight = UITableView.automaticDimension
        activityTypeSummaryTableView.estimatedRowHeight = 48
        activityTypeSummaryTableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        activityTypeSummaryTableView.register(
            ActivityTypeSummaryCell.self,
            forCellReuseIdentifier: ActivityTypeSummaryCell.reuseIdentifier
        )
    }

    private func configureActivitiesSectionTitleLabel() {
        activitiesSectionTitleLabel.text = "Activities"
        activitiesSectionTitleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        activitiesSectionTitleLabel.textColor = AppTheme.metadataText
        activitiesSectionTitleLabel.numberOfLines = 1
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
        emptyStateLabel.text = emptyStateText()
        emptyStateLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .regular)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        activityTagSummaryTableView.backgroundColor = AppTheme.screenBackground
        activityTagSummaryTableView.separatorColor = AppTheme.separator
        activityTypeSummaryTableView.backgroundColor = AppTheme.screenBackground
        activityTypeSummaryTableView.separatorColor = AppTheme.separator
        tableView.backgroundColor = AppTheme.screenBackground
        tableView.separatorColor = AppTheme.separator
        tagSummarySectionTitleLabel.textColor = AppTheme.metadataText
        summarySectionTitleLabel.textColor = AppTheme.metadataText
        activitiesSectionTitleLabel.textColor = AppTheme.metadataText
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
            viewController.activityTagSummaryTableView.reloadData()
            viewController.activityTypeSummaryTableView.reloadData()
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
            activityTagSummaryRows = []
            activityTypeSummaryRows = []
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
            activityTagSummaryRows = makeActivityTagSummaryRows(from: activities)
            activityTypeSummaryRows = makeActivityTypeSummaryRows(from: activities)
            updateContent()
        } catch {
            assertionFailure("Unable to fetch day summary activities: \(error)")
            activityRows = []
            activityTagSummaryRows = []
            activityTypeSummaryRows = []
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

    private func activityIsCompletedFullyInSelectedDay(_ activity: Activity) -> Bool {
        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return false
        }

        let bounds = selectedDayBounds()
        return startTime >= bounds.start && completionTime < bounds.end
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
            noteText: normalizedNote(activity.activityNotes),
            tagTexts: tagPreviewTexts(for: activity.activityType)
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
            noteText: nil,
            tagTexts: tagPreviewTexts(for: activityType)
        )
    }

    private func tagPreviewTexts(for activityType: ActivityType) -> [String] {
        activityType.tags?
            .map(\.name)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending } ?? []
    }

    private func makeActivityTagSummaryRows(from activities: [Activity]) -> [ActivityTagSummaryRow] {
        var summariesByID: [UUID: (name: String, duration: TimeInterval)] = [:]

        for activity in activities where activityIsCompletedFullyInSelectedDay(activity) {
            guard let completionTime = activity.activityCompletionTime else {
                continue
            }

            let duration = activityDuration(for: activity, completionTime: completionTime)
            for tag in activity.activityType.tags ?? [] {
                let existingSummary = summariesByID[tag.uniqueID]
                summariesByID[tag.uniqueID] = (
                    name: tag.name,
                    duration: (existingSummary?.duration ?? 0) + duration
                )
            }
        }

        return summariesByID.map { tagID, summary in
            ActivityTagSummaryRow(
                tagID: tagID,
                tagName: summary.name,
                totalDuration: summary.duration
            )
        }
        .sorted {
            if $0.totalDuration == $1.totalDuration {
                return $0.tagName.localizedCaseInsensitiveCompare($1.tagName) == .orderedAscending
            }

            return $0.totalDuration > $1.totalDuration
        }
    }

    private func makeActivityTypeSummaryRows(from activities: [Activity]) -> [ActivityTypeSummaryRow] {
        var summariesByID: [UUID: (name: String, duration: TimeInterval)] = [:]

        for activity in activities where activityIsCompletedFullyInSelectedDay(activity) {
            guard let completionTime = activity.activityCompletionTime else {
                continue
            }

            let activityType = activity.activityType
            let duration = activityDuration(for: activity, completionTime: completionTime)
            let existingSummary = summariesByID[activityType.uniqueID]
            summariesByID[activityType.uniqueID] = (
                name: activityType.name,
                duration: (existingSummary?.duration ?? 0) + duration
            )
        }

        return summariesByID.map { activityTypeID, summary in
            ActivityTypeSummaryRow(
                activityTypeID: activityTypeID,
                activityTypeName: summary.name,
                totalDuration: summary.duration
            )
        }
        .sorted {
            if $0.totalDuration == $1.totalDuration {
                return $0.activityTypeName.localizedCaseInsensitiveCompare($1.activityTypeName) == .orderedAscending
            }

            return $0.totalDuration > $1.totalDuration
        }
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
        activityTagSummaryTableView.reloadData()
        activityTypeSummaryTableView.reloadData()
        tableView.reloadData()
        emptyStateLabel.text = emptyStateText()
        emptyStateLabel.isHidden = !activityRows.isEmpty
        updateSummarySectionVisibility()
    }

    private func updateSummarySectionVisibility() {
        let shouldShowTagSummary = !activityRows.isEmpty && !activityTagSummaryRows.isEmpty
        let shouldShowTypeSummary = !activityRows.isEmpty && !activityTypeSummaryRows.isEmpty
        tagSummarySectionTitleLabel.isHidden = !shouldShowTagSummary
        activityTagSummaryTableView.isHidden = !shouldShowTagSummary
        summarySectionTitleLabel.isHidden = !shouldShowTypeSummary
        activityTypeSummaryTableView.isHidden = !shouldShowTypeSummary
        activitiesSectionTitleLabel.isHidden = activityRows.isEmpty

        activityTypeSectionTopToTagConstraint?.isActive = shouldShowTypeSummary && shouldShowTagSummary
        activityTypeSectionTopToHeaderConstraint?.isActive = shouldShowTypeSummary && !shouldShowTagSummary
        activitiesSectionTopToSummaryConstraint?.isActive = !activityRows.isEmpty && shouldShowTypeSummary
        activitiesSectionTopToTagConstraint?.isActive = !activityRows.isEmpty && !shouldShowTypeSummary && shouldShowTagSummary
        activitiesSectionTopToHeaderConstraint?.isActive = activityRows.isEmpty || (!shouldShowTypeSummary && !shouldShowTagSummary)

        let rowHeight: CGFloat = 48
        let maximumHeight: CGFloat = 220
        activityTagSummaryTableHeightConstraint?.constant = shouldShowTagSummary
            ? min(CGFloat(activityTagSummaryRows.count) * rowHeight, maximumHeight)
            : 0
        activityTypeSummaryTableHeightConstraint?.constant = shouldShowTypeSummary
            ? min(CGFloat(activityTypeSummaryRows.count) * rowHeight, maximumHeight)
            : 0
        activityTagSummaryTableView.isScrollEnabled = CGFloat(activityTagSummaryRows.count) * rowHeight > maximumHeight
        activityTypeSummaryTableView.isScrollEnabled = CGFloat(activityTypeSummaryRows.count) * rowHeight > maximumHeight
    }

    private func emptyStateText() -> String {
        if isSelectedDayToday(), Calendar.current.component(.hour, from: Date()) < 10 {
            return Self.earlyTodayEmptyStateText
        }

        return Self.emptyStateQuotes.randomElement() ?? Self.earlyTodayEmptyStateText
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
        if tableView === activityTagSummaryTableView {
            return activityTagSummaryRows.count
        }

        if tableView === activityTypeSummaryTableView {
            return activityTypeSummaryRows.count
        }

        return activityRows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if tableView === activityTagSummaryTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ActivityTypeSummaryCell.reuseIdentifier,
                for: indexPath
            ) as? ActivityTypeSummaryCell
            cell?.configure(with: activityTagSummaryRows[indexPath.row])
            return cell ?? UITableViewCell()
        }

        if tableView === activityTypeSummaryTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ActivityTypeSummaryCell.reuseIdentifier,
                for: indexPath
            ) as? ActivityTypeSummaryCell
            cell?.configure(with: activityTypeSummaryRows[indexPath.row])
            return cell ?? UITableViewCell()
        }

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

        guard tableView !== activityTagSummaryTableView else {
            return
        }

        guard tableView !== activityTypeSummaryTableView else {
            return
        }

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
