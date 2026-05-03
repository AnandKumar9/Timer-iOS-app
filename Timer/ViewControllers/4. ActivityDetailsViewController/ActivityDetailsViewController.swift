import UIKit
import SwiftData

final class ActivityDetailsViewController: UIViewController {
    private final class DetailRowView: UIView {
        private let iconView = UIImageView()
        private let titleLabel = UILabel()
        private let valueLabel = UILabel()

        init(iconName: String, title: String, value: String) {
            super.init(frame: .zero)
            configure(iconName: iconName, title: title, value: value)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure(iconName: "circle", title: "", value: "")
        }

        private func configure(iconName: String, title: String, value: String) {
            let textStackView = UIStackView()

            backgroundColor = .clear

            iconView.image = UIImage(systemName: iconName)
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            iconView.tintColor = .secondaryLabel
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false

            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = .secondaryLabel
            titleLabel.numberOfLines = 1

            valueLabel.text = value
            valueLabel.font = .systemFont(ofSize: 17, weight: .medium)
            valueLabel.textColor = .label
            valueLabel.numberOfLines = 0
            valueLabel.lineBreakMode = .byWordWrapping

            textStackView.axis = .vertical
            textStackView.spacing = 3
            textStackView.translatesAutoresizingMaskIntoConstraints = false
            textStackView.addArrangedSubview(titleLabel)
            textStackView.addArrangedSubview(valueLabel)

            addSubview(iconView)
            addSubview(textStackView)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
                iconView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                iconView.widthAnchor.constraint(equalToConstant: 26),
                iconView.heightAnchor.constraint(equalToConstant: 26),

                textStackView.topAnchor.constraint(equalTo: topAnchor),
                textStackView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                textStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                textStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let activityNameLabel = UILabel()
    private let statusCapsuleLabel = UILabel()
    private let durationValueLabel = UILabel()
    private let detailsContainerView = UIView()
    private let detailsStackView = UIStackView()

    var modelContext: ModelContext?
    var activity: Activity?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        populateActivityDetails()
    }

    private func configureAppearance() {
        title = "Activity Details"
        view.backgroundColor = .systemGroupedBackground

        configureScrollView()
        configureContentStackView()
        configureHeader()
        configureSummaryCard()
        configureDetailsContainer()

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func configureScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureContentStackView() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 18
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureHeader() {
        let titleCaptionLabel = UILabel()
        titleCaptionLabel.text = "Activity Type"
        titleCaptionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleCaptionLabel.textColor = .secondaryLabel
        titleCaptionLabel.textAlignment = .center

        activityNameLabel.font = .systemFont(ofSize: 36, weight: .bold)
        activityNameLabel.textColor = .label
        activityNameLabel.textAlignment = .center
        activityNameLabel.numberOfLines = 2
        activityNameLabel.adjustsFontSizeToFitWidth = true
        activityNameLabel.minimumScaleFactor = 0.72

        statusCapsuleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusCapsuleLabel.textAlignment = .center
        statusCapsuleLabel.layer.cornerRadius = 13
        statusCapsuleLabel.layer.cornerCurve = .continuous
        statusCapsuleLabel.clipsToBounds = true
        statusCapsuleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let statusContainerView = UIView()
        statusContainerView.addSubview(statusCapsuleLabel)
        statusCapsuleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusCapsuleLabel.topAnchor.constraint(equalTo: statusContainerView.topAnchor),
            statusCapsuleLabel.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            statusCapsuleLabel.bottomAnchor.constraint(equalTo: statusContainerView.bottomAnchor),
            statusCapsuleLabel.heightAnchor.constraint(equalToConstant: 26),
            statusCapsuleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])

        let headerStackView = UIStackView(arrangedSubviews: [
            titleCaptionLabel,
            activityNameLabel,
            statusContainerView
        ])
        headerStackView.axis = .vertical
        headerStackView.spacing = 8
        contentStackView.addArrangedSubview(headerStackView)
    }

    private func configureSummaryCard() {
        let summaryCardView = UIView()
        summaryCardView.backgroundColor = .secondarySystemGroupedBackground
        summaryCardView.layer.cornerRadius = 8
        summaryCardView.layer.cornerCurve = .continuous
        summaryCardView.translatesAutoresizingMaskIntoConstraints = false

        let durationTitleLabel = UILabel()
        durationTitleLabel.text = "Duration"
        durationTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        durationTitleLabel.textColor = .secondaryLabel
        durationTitleLabel.textAlignment = .center

        durationValueLabel.font = .monospacedDigitSystemFont(ofSize: 42, weight: .bold)
        durationValueLabel.textColor = .label
        durationValueLabel.textAlignment = .center
        durationValueLabel.numberOfLines = 1
        durationValueLabel.adjustsFontSizeToFitWidth = true
        durationValueLabel.minimumScaleFactor = 0.62

        let summaryStackView = UIStackView(arrangedSubviews: [
            durationTitleLabel,
            durationValueLabel
        ])
        summaryStackView.axis = .vertical
        summaryStackView.alignment = .fill
        summaryStackView.spacing = 8
        summaryStackView.translatesAutoresizingMaskIntoConstraints = false

        summaryCardView.addSubview(summaryStackView)
        contentStackView.addArrangedSubview(summaryCardView)

        NSLayoutConstraint.activate([
            summaryStackView.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 22),
            summaryStackView.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            summaryStackView.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -18),
            summaryStackView.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -22)
        ])
    }

    private func configureDetailsContainer() {
        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = "Stored Fields"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        sectionTitleLabel.textColor = .label

        detailsContainerView.backgroundColor = .secondarySystemGroupedBackground
        detailsContainerView.layer.cornerRadius = 8
        detailsContainerView.layer.cornerCurve = .continuous

        detailsStackView.axis = .vertical
        detailsStackView.spacing = 18
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false

        detailsContainerView.addSubview(detailsStackView)

        let sectionStackView = UIStackView(arrangedSubviews: [
            sectionTitleLabel,
            detailsContainerView
        ])
        sectionStackView.axis = .vertical
        sectionStackView.spacing = 10
        contentStackView.addArrangedSubview(sectionStackView)

        NSLayoutConstraint.activate([
            detailsStackView.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: 18),
            detailsStackView.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 18),
            detailsStackView.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -18),
            detailsStackView.bottomAnchor.constraint(equalTo: detailsContainerView.bottomAnchor, constant: -18)
        ])
    }

    private func populateActivityDetails() {
        guard let activity else {
            activityNameLabel.text = "Activity"
            configureStatusCapsule(text: "Unavailable", color: .systemGray)
            durationValueLabel.text = "Unavailable"
            setDetailRows([
                DetailRowView(iconName: "exclamationmark.circle", title: "Activity", value: "Unavailable")
            ])
            return
        }

        let startTimeText = formattedDateTime(activity.activityStartTime)
        let completionTimeText = formattedDateTime(activity.activityCompletionTime)
        let duration = resolvedDuration(for: activity)

        activityNameLabel.text = activity.activityType.name
        configureStatusCapsule(
            text: statusText(for: activity),
            color: statusColor(for: activity)
        )
        durationValueLabel.text = formattedDuration(duration)

        setDetailRows([
            DetailRowView(iconName: "tag.fill", title: "Activity Type Name", value: activity.activityType.name),
            DetailRowView(iconName: "timer", title: "Time Taken", value: formattedDuration(activity.timeTaken)),
            DetailRowView(iconName: "calendar.badge.plus", title: "Activity Start Time", value: startTimeText),
            DetailRowView(iconName: "checkmark.circle.fill", title: "Activity Completion Time", value: completionTimeText),
        ])
    }

    private func setDetailRows(_ rows: [DetailRowView]) {
        detailsStackView.arrangedSubviews.forEach { view in
            detailsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rows.enumerated().forEach { index, row in
            if index > 0 {
                detailsStackView.addArrangedSubview(makeDividerView())
            }
            detailsStackView.addArrangedSubview(row)
        }
    }

    private func makeDividerView() -> UIView {
        let dividerView = UIView()
        dividerView.backgroundColor = .separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return dividerView
    }

    private func configureStatusCapsule(text: String, color: UIColor) {
        statusCapsuleLabel.text = "  \(text)  "
        statusCapsuleLabel.textColor = color
        statusCapsuleLabel.backgroundColor = color.withAlphaComponent(0.14)
    }

    private func statusText(for activity: Activity) -> String {
        if activity.activityCompletionTime != nil {
            return "Completed"
        }

        if activity.activityStartTime != nil {
            return "In Progress"
        }

        return "Not Started"
    }

    private func statusColor(for activity: Activity) -> UIColor {
        if activity.activityCompletionTime != nil {
            return .systemGreen
        }

        if activity.activityStartTime != nil {
            return .systemOrange
        }

        return .systemGray
    }

    private func resolvedDuration(for activity: Activity) -> TimeInterval? {
        if let timeTaken = activity.timeTaken {
            return timeTaken
        }

        guard
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime
        else {
            return nil
        }

        return completionTime.timeIntervalSince(startTime)
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else {
            return "Unavailable"
        }

        let seconds = max(0, Int(duration.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d hr %02d min %02d sec", hours, minutes, remainingSeconds)
        }

        if minutes > 0 {
            return String(format: "%d min %02d sec", minutes, remainingSeconds)
        }

        return "\(remainingSeconds) sec"
    }

    private func formattedDateTime(_ date: Date?) -> String {
        guard let date else {
            return "Unavailable"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy (EEE), h:mm:ss a"
        return formatter.string(from: date)
    }

}

extension ActivityDetailsViewController: FloatingTimerButtonContextProviding {
    var floatingTimerButtonContext: FloatingTimerButtonContext? {
        guard let activityType = activity?.activityType else {
            return nil
        }

        return .activityType(activityType)
    }
}
