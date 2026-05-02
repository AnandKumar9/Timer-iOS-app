import UIKit
import SwiftData

final class TimerViewController: UIViewController {
    fileprivate static var activeInstance: TimerViewController?
    fileprivate static var activeNavigationController: UINavigationController?

    private let scrollView = UIScrollView()
    private let timerControlsStackView = UIStackView()
    private var timerControlsViews: [TimerControlsView] = []
    private var didPromptForInitialActivityType = false
    private var initialActivityType: ActivityType?

    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()

        Self.activeInstance = self
        configureAppearance()
        configureTimerPersistence()

        if let initialActivityType {
            didPromptForInitialActivityType = true
            appendTimerControlsView(activityType: initialActivityType)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        promptForInitialActivityTypeIfNeeded()
    }

    private func configureAppearance() {
        title = "Timers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Activity Types",
            style: .plain,
            target: self,
            action: #selector(activityTypesButtonTapped)
        )

        view.backgroundColor = .systemBackground

        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        timerControlsStackView.axis = .vertical
        timerControlsStackView.spacing = 28
        timerControlsStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(timerControlsStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            timerControlsStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 48),
            timerControlsStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            timerControlsStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            timerControlsStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            timerControlsStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    private func configureTimerPersistence() {
    }

    func configure(activityType: ActivityType) {
        if let existingTimerControlsView = reusableTimerControlsView(activityType: activityType) {
            scrollToTimerControlsView(existingTimerControlsView)
            return
        }

        initialActivityType = activityType

        if isViewLoaded {
            didPromptForInitialActivityType = true
            appendTimerControlsView(activityType: activityType)
        }
    }

    @objc private func activityTypesButtonTapped() {
        let presentingNavigationController = mainPresentingNavigationController()

        dismiss(animated: true) {
            presentingNavigationController?.popToRootViewController(animated: true)
        }
    }

    private func mainPresentingNavigationController() -> UINavigationController? {
        let presentingViewController = navigationController?.presentingViewController ?? presentingViewController

        if let navigationController = presentingViewController as? UINavigationController {
            return navigationController
        }

        return presentingViewController?.navigationController
    }

    private func makeTimerActivity(activityType: ActivityType) -> Activity {
        return Activity(activityType: activityType)
    }

    private func appendTimerControlsView(activityType: ActivityType) {
        removeExpiredInactiveTimerControls()

        let activity = makeTimerActivity(activityType: activityType)
        let timerControlsView = TimerControlsView(activity: activity)
        timerControlsView.translatesAutoresizingMaskIntoConstraints = false
        timerControlsView.onActivityStopped = { [weak self] activity in
            self?.saveTimerActivity(activity)
        }

        timerControlsStackView.addArrangedSubview(timerControlsView)
        timerControlsViews.append(timerControlsView)
        scrollToTimerControlsView(timerControlsView)
    }

    private func reusableTimerControlsView(activityType: ActivityType) -> TimerControlsView? {
        removeExpiredInactiveTimerControls()

        return timerControlsViews.first {
            $0.activityTypeID == activityType.uniqueID && !$0.hasCompletedTimer
        }
    }

    private func scrollToTimerControlsView(_ timerControlsView: TimerControlsView) {
        view.layoutIfNeeded()

        let targetRect = timerControlsView.convert(timerControlsView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(targetRect.insetBy(dx: 0, dy: -24), animated: true)
    }

    private func removeExpiredInactiveTimerControls() {
        let cutoffDate = Date().addingTimeInterval(-86_400)
        let expiredTimerControlsViews = timerControlsViews.filter { timerControlsView in
            guard
                !timerControlsView.hasActiveTimer,
                let stoppedAt = timerControlsView.stoppedAt
            else {
                return false
            }

            return stoppedAt < cutoffDate
        }

        for timerControlsView in expiredTimerControlsViews {
            timerControlsStackView.removeArrangedSubview(timerControlsView)
            timerControlsView.removeFromSuperview()
        }

        timerControlsViews.removeAll { timerControlsView in
            expiredTimerControlsViews.contains { $0 === timerControlsView }
        }
    }

    private func promptForInitialActivityTypeIfNeeded() {
        guard !didPromptForInitialActivityType else {
            return
        }

        didPromptForInitialActivityType = true

        guard timerControlsViews.isEmpty else {
            return
        }

        guard let modelContext else {
            return
        }

        var descriptor = FetchDescriptor<ActivityType>()
        descriptor.fetchLimit = 1

        do {
            if try modelContext.fetch(descriptor).isEmpty {
                presentCreateActivityTypeAlert()
            }
        } catch {
            assertionFailure("Unable to check activity types: \(error)")
        }
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

            self?.createInitialActivityType(named: name)
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

    private func createInitialActivityType(named name: String) {
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
            appendTimerControlsView(activityType: activityType)
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

    private func saveTimerActivity(_ activity: Activity) {
        guard let modelContext else {
            return
        }

        guard activity.activityStartTime != nil else {
            return
        }

        if !activity.activityType.activities.contains(where: { $0 === activity }) {
            activity.activityType.activities.append(activity)
        }

        modelContext.insert(activity)

        do {
            try modelContext.save()
            removeExpiredInactiveTimerControls()
        } catch {
            modelContext.delete(activity)
            assertionFailure("Unable to save timer activity: \(error)")
        }
    }
}

extension UIViewController {
    func presentTimerViewController(
        modelContext: ModelContext?,
        activityType: ActivityType? = nil
    ) {
        if let timerViewController = TimerViewController.activeInstance,
           let navigationController = TimerViewController.activeNavigationController {
            timerViewController.modelContext = modelContext

            if let activityType {
                timerViewController.configure(activityType: activityType)
            }

            guard navigationController.presentingViewController == nil else {
                return
            }

            present(navigationController, animated: true)
            return
        }

        let timerViewController = TimerViewController(nibName: "TimerViewController", bundle: nil)
        timerViewController.modelContext = modelContext

        if let activityType {
            timerViewController.configure(activityType: activityType)
        }

        let navigationController = UINavigationController(rootViewController: timerViewController)
        navigationController.modalPresentationStyle = .pageSheet
        TimerViewController.activeInstance = timerViewController
        TimerViewController.activeNavigationController = navigationController
        present(navigationController, animated: true)
    }
}
