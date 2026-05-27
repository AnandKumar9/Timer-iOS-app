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
        "Organized chaos is still a system.",
        "No roadmap, just momentum.",
        "The plan is to adapt until it works.",
        "Chaos, but with follow-through.",
        "I prefer flexible ambition over rigid planning.",
        "Winging it has surprisingly good results sometimes.",
        "Direction matters more than detailed planning.",
        "I’m less ‘master plan’ and more ‘continuous improvisation.’",
        "Somehow, everything works out between procrastination and panic.",
        "I believe in spontaneous productivity.",
        "I like plans that leave room for better ideas.",
        "I run on instincts, and caffeine.",
        "Not all who wander are lost. Some are just figuring it out live.",
        "My strategy is simple: start somewhere and adjust aggressively.",
        "I don’t always have a plan, but things somehow get done.",
        "I’m not lazy. I’m just highly motivated to do nothing.",
        "My life feels like a test I didn’t study for.",
        "I followed my heart. It led me to the fridge.",
        "Some people wake up productive. I wake up.",
        "My brain has too many tabs open.",
        "I finally got eight hours of sleep. It took me three days.",
        "I’m not arguing. I’m just passionately explaining why I’m correct.",
        "I love pressing the snooze button like it’ll change my life.",
        "I’m at a place in my life where errands are considered going out.",
        "The problem with the future is that it keeps turning into the present.",
        "Done is better than perfect.",
        "Start before you feel ready.",
        "Dream big. Start small. Complain less.",
        "Success is mostly just not quitting.",
        "The secret ingredient is usually persistence.",
        "Not every hour has to be productive. Some are for playlists and vibes.",
        "Spent the whole day chilling but the soundtrack was incredible.",
        "Sometimes the most productive thing you can do is absolutely nothing with great music playing.",
        "Some people track time. I track story arcs.",
    ]

    private final class DaySummaryCell: UITableViewCell {
        static let reuseIdentifier = "DaySummaryCell"
        private static let compactPhoneMaximumWidth: CGFloat = 375
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
        private let titleStackView = UIStackView()
        private let detailStackView = UIStackView()

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

            updateTagPreviewPlacement()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateTagPreviewPlacement()
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
            activityNameLabel.setContentHuggingPriority(.required, for: .horizontal)
            activityNameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

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
            tagPreviewContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            tagPreviewContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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

            titleStackView.addArrangedSubview(activityNameLabel)
            titleStackView.addArrangedSubview(tagPreviewContainerView)
            titleStackView.addArrangedSubview(durationStackView)
            titleStackView.axis = .horizontal
            titleStackView.alignment = .center
            titleStackView.spacing = 8

            detailStackView.addArrangedSubview(titleStackView)
            detailStackView.addArrangedSubview(noteLabel)
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

            updateTagPreviewPlacement()
        }

        private func updateTagPreviewPlacement() {
            let shouldShowTagsBelowTitle = Self.isCompactPhoneWidth
            let tagPreviewIsBelowTitle = tagPreviewContainerView.superview === detailStackView

            guard shouldShowTagsBelowTitle != tagPreviewIsBelowTitle else {
                return
            }

            if shouldShowTagsBelowTitle {
                titleStackView.removeArrangedSubview(tagPreviewContainerView)
                tagPreviewContainerView.removeFromSuperview()
                detailStackView.insertArrangedSubview(tagPreviewContainerView, at: 1)
            } else {
                detailStackView.removeArrangedSubview(tagPreviewContainerView)
                tagPreviewContainerView.removeFromSuperview()
                titleStackView.insertArrangedSubview(tagPreviewContainerView, at: 1)
            }
        }

        private static var isCompactPhoneWidth: Bool {
            guard UIDevice.current.userInterfaceIdiom == .phone else {
                return false
            }

            let screenSize = UIScreen.main.bounds.size
            return min(screenSize.width, screenSize.height) <= compactPhoneMaximumWidth
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

        private let nameLabel = UILabel()
        private let tagPreviewContainerView = UIView()
        private let tagPreviewStackView = UIStackView()
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
            configure(
                name: row.activityTypeName,
                durationText: row.durationText,
                tagTexts: row.tagTexts
            )
        }

        func configure(with row: ActivityTagSummaryRow) {
            configure(name: row.tagName, durationText: row.durationText, tagTexts: [])
        }

        private func configure(name: String, durationText: String, tagTexts: [String]) {
            backgroundColor = AppTheme.screenBackground
            contentView.backgroundColor = AppTheme.screenBackground
            selectedBackgroundView?.backgroundColor = AppTheme.controlBackground

            nameLabel.text = name
            nameLabel.textColor = AppTheme.primaryText
            configureTagPreviews(tagTexts)
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
            nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

            tagPreviewContainerView.clipsToBounds = true
            tagPreviewContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            tagPreviewContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            tagPreviewStackView.axis = .horizontal
            tagPreviewStackView.alignment = .center
            tagPreviewStackView.spacing = 6
            tagPreviewStackView.translatesAutoresizingMaskIntoConstraints = false
            tagPreviewContainerView.addSubview(tagPreviewStackView)

            durationLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .semibold)
            durationLabel.numberOfLines = 1
            durationLabel.textAlignment = .right
            durationLabel.setContentHuggingPriority(.required, for: .horizontal)
            durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            let rowStackView = UIStackView(arrangedSubviews: [
                nameLabel,
                tagPreviewContainerView,
                durationLabel
            ])
            rowStackView.axis = .horizontal
            rowStackView.alignment = .center
            rowStackView.spacing = 8
            rowStackView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(rowStackView)

            NSLayoutConstraint.activate([
                tagPreviewStackView.leadingAnchor.constraint(equalTo: tagPreviewContainerView.leadingAnchor),
                tagPreviewStackView.topAnchor.constraint(equalTo: tagPreviewContainerView.topAnchor),
                tagPreviewStackView.bottomAnchor.constraint(equalTo: tagPreviewContainerView.bottomAnchor),
                tagPreviewStackView.trailingAnchor.constraint(lessThanOrEqualTo: tagPreviewContainerView.trailingAnchor),

                rowStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                rowStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                rowStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                rowStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
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
        let tagTexts: [String]

        var durationText: String {
            ActivityDisplayFormatter.roundedHistoryDurationText(for: totalDuration)
        }
    }

    private struct ActivityTagSummaryRow {
        let tagID: UUID?
        let tagName: String
        let totalDuration: TimeInterval

        var durationText: String {
            if AppSettings.showDurationSeconds {
                return ActivityDisplayFormatter.roundedHistoryDurationText(for: totalDuration)
            }

            return Self.approximateCategoryDurationText(for: totalDuration)
        }

        static func shouldShow(totalDuration: TimeInterval) -> Bool {
            if AppSettings.showDurationSeconds {
                return true
            }

            return totalDuration >= 15 * 60
        }

        private static func approximateCategoryDurationText(for duration: TimeInterval) -> String {
            let halfHourMinutes = 30
            let totalMinutes = max(0, duration / 60)
            let roundedHalfHours = max(
                1,
                Int((totalMinutes / Double(halfHourMinutes)).rounded(.toNearestOrAwayFromZero))
            )
            let roundedMinutes = roundedHalfHours * halfHourMinutes

            guard roundedMinutes > halfHourMinutes else {
                return "30 min"
            }

            let hours = roundedMinutes / 60
            if roundedMinutes.isMultiple(of: 60) {
                return "\(hours) hr"
            }

            return "\(hours).5 hr"
        }
    }

    private enum SummarySection {
        case tagTotals
        case activityTypeTotals
        case activities

        var title: String {
            switch self {
            case .tagTotals:
                return "Activity Categories"
            case .activityTypeTotals:
                return "Activity Types"
            case .activities:
                return "Activities"
            }
        }

        var subtitle: String? {
            switch self {
            case .tagTotals:
                if AppSettings.showDurationSeconds {
                    return nil
                }

                return "Approximate time by category, rounded to the nearest 30 minutes."
            case .activityTypeTotals, .activities:
                return nil
            }
        }
    }

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
    private var remainingEmptyStateQuotes = SummarizeMyDayViewController.emptyStateQuotes.shuffled()
    private var emptyStateQuotesByDay: [Date: String] = [:]
    private var selectedDay: Date

    private var visibleSections: [SummarySection] {
        var sections: [SummarySection] = []

        if !activityTagSummaryRows.isEmpty {
            sections.append(.tagTotals)
        }

        if !activityTypeSummaryRows.isEmpty {
            sections.append(.activityTypeTotals)
        }

        if !activityRows.isEmpty {
            sections.append(.activities)
        }

        return sections
    }

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

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        tableView.register(
            ActivityTypeSummaryCell.self,
            forCellReuseIdentifier: ActivityTypeSummaryCell.reuseIdentifier
        )
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
        var uncategorizedDuration: TimeInterval = 0

        for activity in activities where activityIsCompletedFullyInSelectedDay(activity) {
            guard let completionTime = activity.activityCompletionTime else {
                continue
            }

            let duration = activityDuration(for: activity, completionTime: completionTime)
            let tags = activity.activityType.tags ?? []

            guard !tags.isEmpty else {
                uncategorizedDuration += duration
                continue
            }

            for tag in tags {
                let existingSummary = summariesByID[tag.uniqueID]
                summariesByID[tag.uniqueID] = (
                    name: tag.name,
                    duration: (existingSummary?.duration ?? 0) + duration
                )
            }
        }

        guard !summariesByID.isEmpty else {
            return []
        }

        var rows: [ActivityTagSummaryRow] = summariesByID.compactMap { tagID, summary in
            guard ActivityTagSummaryRow.shouldShow(totalDuration: summary.duration) else {
                return nil
            }

            return ActivityTagSummaryRow(
                tagID: tagID,
                tagName: summary.name,
                totalDuration: summary.duration
            )
        }

        if ActivityTagSummaryRow.shouldShow(totalDuration: uncategorizedDuration) {
            rows.append(
                ActivityTagSummaryRow(
                    tagID: nil,
                    tagName: "Uncategorized",
                    totalDuration: uncategorizedDuration
                )
            )
        }

        return rows
        .sorted {
            if $0.tagID == nil {
                return false
            }

            if $1.tagID == nil {
                return true
            }

            if $0.totalDuration == $1.totalDuration {
                return $0.tagName.localizedCaseInsensitiveCompare($1.tagName) == .orderedAscending
            }

            return $0.totalDuration > $1.totalDuration
        }
    }

    private func makeActivityTypeSummaryRows(from activities: [Activity]) -> [ActivityTypeSummaryRow] {
        var summariesByID: [UUID: (name: String, duration: TimeInterval, tagTexts: [String])] = [:]

        for activity in activities where activityIsCompletedFullyInSelectedDay(activity) {
            guard let completionTime = activity.activityCompletionTime else {
                continue
            }

            let activityType = activity.activityType
            let duration = activityDuration(for: activity, completionTime: completionTime)
            let existingSummary = summariesByID[activityType.uniqueID]
            summariesByID[activityType.uniqueID] = (
                name: activityType.name,
                duration: (existingSummary?.duration ?? 0) + duration,
                tagTexts: existingSummary?.tagTexts ?? tagPreviewTexts(for: activityType)
            )
        }

        return summariesByID.map { activityTypeID, summary in
            ActivityTypeSummaryRow(
                activityTypeID: activityTypeID,
                activityTypeName: summary.name,
                totalDuration: summary.duration,
                tagTexts: summary.tagTexts
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
        tableView.reloadData()
        let isEmpty = visibleSections.isEmpty
        emptyStateLabel.text = isEmpty ? emptyStateText() : nil
        emptyStateLabel.isHidden = !isEmpty
    }

    private func emptyStateText() -> String {
        if isSelectedDayToday(), Calendar.current.component(.hour, from: Date()) < 10 {
            return Self.earlyTodayEmptyStateText
        }

        let selectedStartOfDay = Calendar.current.startOfDay(for: selectedDay)
        if let cachedQuote = emptyStateQuotesByDay[selectedStartOfDay] {
            return cachedQuote
        }

        if remainingEmptyStateQuotes.isEmpty {
            remainingEmptyStateQuotes = Self.emptyStateQuotes.shuffled()
        }

        let quote = remainingEmptyStateQuotes.popLast() ?? Self.earlyTodayEmptyStateText
        emptyStateQuotesByDay[selectedStartOfDay] = quote
        return quote
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
    func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch visibleSections[section] {
        case .tagTotals:
            return activityTagSummaryRows.count
        case .activityTypeTotals:
            return activityTypeSummaryRows.count
        case .activities:
            return activityRows.count
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch visibleSections[indexPath.section] {
        case .tagTotals:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ActivityTypeSummaryCell.reuseIdentifier,
                for: indexPath
            ) as? ActivityTypeSummaryCell
            cell?.configure(with: activityTagSummaryRows[indexPath.row])
            return cell ?? UITableViewCell()
        case .activityTypeTotals:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ActivityTypeSummaryCell.reuseIdentifier,
                for: indexPath
            ) as? ActivityTypeSummaryCell
            cell?.configure(with: activityTypeSummaryRows[indexPath.row])
            return cell ?? UITableViewCell()
        case .activities:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DaySummaryCell.reuseIdentifier,
                for: indexPath
            ) as? DaySummaryCell
            cell?.configure(with: activityRows[indexPath.row])
            return cell ?? UITableViewCell()
        }
    }
}

extension SummarizeMyDayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard visibleSections[indexPath.section] == .activities else {
            return
        }

        guard case let .completed(activity) = activityRows[indexPath.row].source else {
            return
        }

        showActivityDetails(for: activity)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = AppTheme.screenBackground

        let titleLabel = UILabel()
        titleLabel.text = visibleSections[section].title
        titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = AppTheme.metadataText
        titleLabel.numberOfLines = 1

        let labels: [UILabel]
        if let subtitle = visibleSections[section].subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = AppTheme.roundedFont(ofSize: 12, weight: .regular)
            subtitleLabel.textColor = AppTheme.metadataText
            subtitleLabel.numberOfLines = 0
            labels = [titleLabel, subtitleLabel]
        } else {
            labels = [titleLabel]
        }

        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])

        return containerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        visibleSections[section].subtitle == nil ? 44 : UITableView.automaticDimension
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
