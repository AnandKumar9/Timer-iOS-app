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
            iconView.tintColor = AppTheme.metadataText
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false

            titleLabel.text = title
            titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = AppTheme.metadataText
            titleLabel.numberOfLines = 1

            valueLabel.text = value
            valueLabel.font = AppTheme.roundedFont(ofSize: 17, weight: .medium)
            valueLabel.textColor = AppTheme.primaryText
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

    private final class EditableDateRowView: UIView {
        private let iconView = UIImageView()
        private let titleLabel = UILabel()
        let datePicker = UIDatePicker()

        init(iconName: String, title: String, date: Date) {
            super.init(frame: .zero)
            configure(iconName: iconName, title: title, date: date)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure(iconName: "calendar", title: "", date: Date())
        }

        private func configure(iconName: String, title: String, date: Date) {
            let textStackView = UIStackView()

            iconView.image = UIImage(systemName: iconName)
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            iconView.tintColor = AppTheme.metadataText
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false

            titleLabel.text = title
            titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = AppTheme.metadataText

            datePicker.date = date
            datePicker.datePickerMode = .dateAndTime
            datePicker.preferredDatePickerStyle = .compact
            datePicker.tintColor = AppTheme.accent
            datePicker.translatesAutoresizingMaskIntoConstraints = false

            textStackView.axis = .vertical
            textStackView.spacing = 6
            textStackView.translatesAutoresizingMaskIntoConstraints = false
            textStackView.addArrangedSubview(titleLabel)
            textStackView.addArrangedSubview(datePicker)

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

    private final class EditableActivityTypeRowView: UIView {
        private let iconView = UIImageView()
        private let titleLabel = UILabel()
        let selectionButton = UIButton(type: .system)

        init(iconName: String, title: String, selectedName: String) {
            super.init(frame: .zero)
            configure(iconName: iconName, title: title, selectedName: selectedName)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure(iconName: "tag.fill", title: "", selectedName: "")
        }

        private func configure(iconName: String, title: String, selectedName: String) {
            let textStackView = UIStackView()

            iconView.image = UIImage(systemName: iconName)
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            iconView.tintColor = AppTheme.metadataText
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false

            titleLabel.text = title
            titleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = AppTheme.metadataText

            var configuration = UIButton.Configuration.tinted()
            configuration.title = selectedName
            configuration.image = UIImage(systemName: "chevron.up.chevron.down")
            configuration.imagePlacement = .trailing
            configuration.imagePadding = 8
            configuration.baseForegroundColor = AppTheme.accent
            selectionButton.configuration = configuration
            selectionButton.contentHorizontalAlignment = .leading
            selectionButton.showsMenuAsPrimaryAction = true

            textStackView.axis = .vertical
            textStackView.spacing = 6
            textStackView.translatesAutoresizingMaskIntoConstraints = false
            textStackView.addArrangedSubview(titleLabel)
            textStackView.addArrangedSubview(selectionButton)

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

        func updateSelectedName(_ selectedName: String) {
            var configuration = selectionButton.configuration ?? UIButton.Configuration.tinted()
            configuration.title = selectedName
            selectionButton.configuration = configuration
        }
    }

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let activityNameLabel = UILabel()
    private let statusCapsuleLabel = UILabel()
    private let durationValueLabel = UILabel()
    private let detailsContainerView = UIView()
    private let detailsStackView = UIStackView()
    private let editSaveButton = UIButton(type: .system)
    private var startDatePicker: UIDatePicker?
    private var completionDatePicker: UIDatePicker?
    private var isEditingActivityDetails = false
    private var originalStartTime: Date?
    private var originalCompletionTime: Date?
    private var originalActivityTypeID: UUID?
    private var availableActivityTypes: [ActivityType] = []
    private var selectedActivityType: ActivityType?

    var modelContext: ModelContext?
    var activity: Activity?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyTheme()
        }
        populateActivityDetails()
    }

    private func configureAppearance() {
        title = "Activity Details"
        applyTheme()

        configureScrollView()
        configureContentStackView()
        configureHeader()
        configureSummaryCard()
        configureDetailsContainer()
        configureEditSaveButton()

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(editSaveButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            editSaveButton.widthAnchor.constraint(equalToConstant: 56),
            editSaveButton.heightAnchor.constraint(equalToConstant: 56),
            editSaveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editSaveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func applyTheme() {
        view.backgroundColor = AppTheme.screenBackground
        scrollView.backgroundColor = AppTheme.screenBackground
        navigationController?.navigationBar.tintColor = AppTheme.accent
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance()
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance()
        navigationController?.navigationBar.compactAppearance = navigationBarAppearance()
    }

    private func navigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.screenBackground
        appearance.shadowColor = AppTheme.separator
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 34, weight: .bold)
        ]
        return appearance
    }

    private func configureScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset.bottom = 88
        scrollView.verticalScrollIndicatorInsets.bottom = 88
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
        titleCaptionLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        titleCaptionLabel.textColor = AppTheme.metadataText
        titleCaptionLabel.textAlignment = .center

        activityNameLabel.font = AppTheme.roundedFont(ofSize: 36, weight: .bold)
        activityNameLabel.textColor = AppTheme.primaryText
        activityNameLabel.textAlignment = .center
        activityNameLabel.numberOfLines = 2
        activityNameLabel.adjustsFontSizeToFitWidth = true
        activityNameLabel.minimumScaleFactor = 0.72

        statusCapsuleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
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
        summaryCardView.backgroundColor = AppTheme.cardBackground
        summaryCardView.layer.cornerRadius = 8
        summaryCardView.layer.cornerCurve = .continuous
        summaryCardView.translatesAutoresizingMaskIntoConstraints = false

        let durationTitleLabel = UILabel()
        durationTitleLabel.text = "Duration"
        durationTitleLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .semibold)
        durationTitleLabel.textColor = AppTheme.metadataText
        durationTitleLabel.textAlignment = .center

        durationValueLabel.font = .monospacedDigitSystemFont(ofSize: 42, weight: .bold)
        durationValueLabel.textColor = AppTheme.durationText
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
        sectionTitleLabel.text = "Activity Info"
        sectionTitleLabel.font = AppTheme.roundedFont(ofSize: 20, weight: .bold)
        sectionTitleLabel.textColor = AppTheme.primaryText

        detailsContainerView.backgroundColor = AppTheme.cardBackground
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

    private func configureEditSaveButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = AppTheme.accent
        configuration.baseForegroundColor = .white
        configuration.image = UIImage(systemName: "pencil")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)

        editSaveButton.configuration = configuration
        editSaveButton.layer.cornerRadius = 18
        editSaveButton.layer.cornerCurve = .continuous
        editSaveButton.clipsToBounds = true
        editSaveButton.layer.shadowColor = UIColor.black.cgColor
        editSaveButton.layer.shadowOpacity = 0.18
        editSaveButton.layer.shadowRadius = 10
        editSaveButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        editSaveButton.translatesAutoresizingMaskIntoConstraints = false
        editSaveButton.accessibilityLabel = "Edit activity"
        editSaveButton.addAction(
            UIAction { [weak self] _ in
                self?.editSaveButtonTapped()
            },
            for: .touchUpInside
        )
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

        if isEditingActivityDetails {
            let activityTypeRow = makeEditableActivityTypeRow(selectedActivityType: selectedActivityType ?? activity.activityType)
            let startDateRow = EditableDateRowView(
                iconName: "calendar.badge.plus",
                title: "Activity Start Time",
                date: activity.activityStartTime ?? Date()
            )
            let completionDateRow = EditableDateRowView(
                iconName: "checkmark.circle.fill",
                title: "Activity Completion Time",
                date: activity.activityCompletionTime ?? Date()
            )
            startDatePicker = startDateRow.datePicker
            completionDatePicker = completionDateRow.datePicker

            setDetailRows([
                activityTypeRow,
                startDateRow,
                completionDateRow,
                makeDeleteActivityButton()
            ])
            return
        }

        startDatePicker = nil
        completionDatePicker = nil
        selectedActivityType = nil
        setDetailRows([
            DetailRowView(iconName: "tag.fill", title: "Activity Type Name", value: activity.activityType.name),
            DetailRowView(iconName: "calendar.badge.plus", title: "Activity Start Time", value: startTimeText),
            DetailRowView(iconName: "checkmark.circle.fill", title: "Activity Completion Time", value: completionTimeText)
        ])
    }

    private func setDetailRows(_ rows: [UIView]) {
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
        dividerView.backgroundColor = AppTheme.separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return dividerView
    }

    private func makeEditableActivityTypeRow(selectedActivityType: ActivityType) -> EditableActivityTypeRowView {
        let row = EditableActivityTypeRowView(
            iconName: "tag.fill",
            title: "Activity Type Name",
            selectedName: selectedActivityType.name
        )
        row.selectionButton.menu = UIMenu(
            children: availableActivityTypes.map { activityType in
                UIAction(
                    title: activityType.name,
                    state: activityType.uniqueID == selectedActivityType.uniqueID ? .on : .off
                ) { [weak self, weak row] _ in
                    self?.selectedActivityType = activityType
                    row?.updateSelectedName(activityType.name)
                }
            }
        )
        return row
    }

    private func makeDeleteActivityButton() -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Delete Activity"
        configuration.image = UIImage(systemName: "trash")
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = AppTheme.destructive.withAlphaComponent(0.14)
        configuration.baseForegroundColor = AppTheme.destructive
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.addAction(
            UIAction { [weak self] _ in
                self?.presentDeleteActivityConfirmationAlert()
            },
            for: .touchUpInside
        )
        return button
    }

    private func configureStatusCapsule(text: String, color: UIColor) {
        statusCapsuleLabel.text = "  \(text)  "
        statusCapsuleLabel.textColor = color
        statusCapsuleLabel.backgroundColor = color.withAlphaComponent(0.14)
    }

    private func editSaveButtonTapped() {
        if isEditingActivityDetails {
            if hasEditedActivityDetails {
                presentSaveConfirmationAlert()
            } else {
                setEditingActivityDetails(false)
            }
        } else {
            setEditingActivityDetails(true)
        }
    }

    private func setEditingActivityDetails(_ isEditing: Bool) {
        if isEditing {
            availableActivityTypes = fetchActivityTypes()
            originalStartTime = activity?.activityStartTime
            originalCompletionTime = activity?.activityCompletionTime
            originalActivityTypeID = activity?.activityType.uniqueID
            selectedActivityType = activity?.activityType
        } else {
            availableActivityTypes = []
            originalStartTime = nil
            originalCompletionTime = nil
            originalActivityTypeID = nil
            selectedActivityType = nil
        }

        isEditingActivityDetails = isEditing
        updateEditSaveButtonAppearance()
        populateActivityDetails()
    }

    private func updateEditSaveButtonAppearance() {
        var configuration = editSaveButton.configuration ?? UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: isEditingActivityDetails ? "checkmark" : "pencil")
        configuration.baseBackgroundColor = isEditingActivityDetails ? AppTheme.completed : AppTheme.accent
        editSaveButton.configuration = configuration
        editSaveButton.accessibilityLabel = isEditingActivityDetails ? "Save activity" : "Edit activity"
    }

    private func saveActivityDetails() {
        guard
            let activity,
            let modelContext,
            let startDate = startDatePicker?.date,
            let completionDate = completionDatePicker?.date,
            let selectedActivityType
        else {
            setEditingActivityDetails(false)
            return
        }

        guard completionDate >= startDate else {
            presentInvalidDateRangeAlert()
            return
        }

        let previousActivityType = activity.activityType
        let previousActivityTypeID = previousActivityType.uniqueID

        if previousActivityType.uniqueID != selectedActivityType.uniqueID {
            previousActivityType.activities.removeAll { $0 === activity }
            activity.activityType = selectedActivityType
            if !selectedActivityType.activities.contains(where: { $0 === activity }) {
                selectedActivityType.activities.append(activity)
            }
        }

        activity.activityStartTime = startDate
        activity.activityCompletionTime = completionDate
        activity.timeTaken = completionDate.timeIntervalSince(startDate)

        do {
            try modelContext.save()
            TimerSessionState.notifyActivityPersisted(activityTypeID: previousActivityTypeID)
            TimerSessionState.notifyActivityPersisted(activityTypeID: selectedActivityType.uniqueID)
            setEditingActivityDetails(false)
        } catch {
            assertionFailure("Unable to save activity details: \(error)")
            presentSaveActivityDetailsErrorAlert()
        }
    }

    private func presentSaveConfirmationAlert() {
        let alertController = UIAlertController(
            title: "Save Changes?",
            message: "Save the edited activity times or discard your changes.",
            preferredStyle: .alert
        )

        alertController.addAction(
            UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.setEditingActivityDetails(false)
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                self?.saveActivityDetails()
            }
        )

        present(alertController, animated: true)
    }

    private func presentDeleteActivityConfirmationAlert() {
        let alertController = UIAlertController(
            title: "Delete Activity?",
            message: "This cannot be undone.",
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(
            UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteActivity()
            }
        )

        present(alertController, animated: true)
    }

    private func deleteActivity() {
        guard let activity, let modelContext else {
            navigationController?.popViewController(animated: true)
            return
        }

        let activityType = activity.activityType
        let activityTypeID = activityType.uniqueID
        activityType.activities.removeAll { $0 === activity }
        modelContext.delete(activity)

        do {
            try modelContext.save()
            TimerSessionState.notifyActivityPersisted(activityTypeID: activityTypeID)
            navigationController?.popViewController(animated: true)
        } catch {
            assertionFailure("Unable to delete activity: \(error)")
            presentDeleteActivityErrorAlert()
        }
    }

    private var hasEditedActivityDetails: Bool {
        guard
            let startDate = startDatePicker?.date,
            let completionDate = completionDatePicker?.date
        else {
            return false
        }

        return !areDatesEqual(startDate, originalStartTime)
            || !areDatesEqual(completionDate, originalCompletionTime)
            || selectedActivityType?.uniqueID != originalActivityTypeID
    }

    private func fetchActivityTypes() -> [ActivityType] {
        guard let modelContext else {
            return activity.map { [$0.activityType] } ?? []
        }

        do {
            let descriptor = FetchDescriptor<ActivityType>(
                sortBy: [SortDescriptor(\.name)]
            )
            let activityTypes = try modelContext.fetch(descriptor)
            if activityTypes.isEmpty, let activity {
                return [activity.activityType]
            }
            return activityTypes
        } catch {
            assertionFailure("Unable to fetch activity types: \(error)")
            return activity.map { [$0.activityType] } ?? []
        }
    }

    private func areDatesEqual(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return abs(lhs.timeIntervalSince(rhs)) < 0.001
        case (.none, .none):
            return true
        case (.some, .none), (.none, .some):
            return false
        }
    }

    private func presentInvalidDateRangeAlert() {
        let alertController = UIAlertController(
            title: "Invalid Time Range",
            message: "Completion time must be after start time.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func presentSaveActivityDetailsErrorAlert() {
        let alertController = UIAlertController(
            title: "Unable to Save Activity",
            message: "Please try again.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
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
            return AppTheme.completed
        }

        if activity.activityStartTime != nil {
            return AppTheme.paused
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
