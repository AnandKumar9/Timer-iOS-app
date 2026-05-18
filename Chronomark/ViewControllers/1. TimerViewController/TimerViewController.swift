import UIKit
import SwiftData

final class TimerViewController: UIViewController {
    fileprivate static var activeInstance: TimerViewController?
    fileprivate static var activeNavigationController: UINavigationController?
    private static let inactiveTimerControlsRetentionInterval: TimeInterval = 5
    private static let timerCacheCheckpointInterval: TimeInterval = 300

    static func hasRunningOrPausedTimer(for activityType: ActivityType) -> Bool {
        timerState(for: activityType) != .none
    }
    static func hasActiveOrRecentTimerControls() -> Bool {
        activeInstance?.hasActiveOrRecentTimerControls() ?? false
    }
    static func secondsUntilNextInactiveTimerControlsExpiration() -> TimeInterval? {
        activeInstance?.secondsUntilNextInactiveTimerControlsExpiration()
    }
    static func timerState(for activityType: ActivityType) -> ActivityTimerState {
        activeInstance?.timerState(activityTypeID: activityType.uniqueID) ?? .none
    }
    static func removeTimerControlsView(for activityTypeID: UUID) {
        activeInstance?.removeTimerControlsView(activityTypeID: activityTypeID)
    }
    @discardableResult
    static func restoreCachedTimersIfNeeded(modelContext: ModelContext?) -> Int {
        guard activeInstance == nil else {
            activeInstance?.modelContext = modelContext
            return 0
        }

        guard
            let modelContext,
            pruneStaleCachesAndCheckForRestorableTimers(modelContext: modelContext)
        else {
            return 0
        }

        let timerViewController = TimerViewController(nibName: "TimerViewController", bundle: nil)
        timerViewController.modelContext = modelContext
        let navigationController = UINavigationController(rootViewController: timerViewController)
        navigationController.modalPresentationStyle = .pageSheet
        activeInstance = timerViewController
        activeNavigationController = navigationController
        timerViewController.loadViewIfNeeded()
        return timerViewController.restoredTimerCacheCount
    }

    private static func pruneStaleCachesAndCheckForRestorableTimers(modelContext: ModelContext) -> Bool {
        do {
            let caches = try modelContext.fetch(FetchDescriptor<ActivityTimerCache>())
            guard !caches.isEmpty else {
                return false
            }

            let activityTypeIDs = Set(
                try modelContext.fetch(FetchDescriptor<ActivityType>())
                    .map(\.uniqueID)
            )
            let restoreCutoffDate = timerCacheRestoreCutoffDate()
            var hasRestorableCache = false
            var didMutateCaches = false

            for cache in caches {
                guard
                    cache.lastUpdateTime >= restoreCutoffDate,
                    activityTypeIDs.contains(cache.activityTypeUniqueID)
                else {
                    modelContext.delete(cache)
                    didMutateCaches = true
                    continue
                }

                hasRestorableCache = true
            }

            if didMutateCaches {
                try modelContext.save()
            }

            return hasRestorableCache
        } catch {
            assertionFailure("Unable to inspect timer caches: \(error)")
            return false
        }
    }

    private static func timerCacheRestoreCutoffDate() -> Date {
        Date().addingTimeInterval(-AppSettings.restoreWindowInterval)
    }

    private let scrollView = UIScrollView()
    private let timerControlsStackView = UIStackView()
    private var timerControlsViews: [TimerControlsView] = []
    private var didPromptForInitialActivityType = false
    private var initialActivityType: ActivityType?
    private var shouldAutoStartInitialActivityType = false
    private var didRestoreTimerCaches = false
    private var restoredTimerCacheCount = 0
    private var timerCacheCheckpointTimer: Timer?
#if DEBUG
    private var screenshotSampleActivityTypes: [ActivityType] = []
    private var screenshotSampleTimers: [ScreenshotSampleTimer] = []
    private var isUsingScreenshotSamples = false
#endif

    var modelContext: ModelContext? {
        didSet {
            guard isViewLoaded else {
                return
            }

            configureTimerPersistence()
        }
    }

    deinit {
        timerCacheCheckpointTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Self.activeInstance = self
        configureAppearance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyTheme()
        }
        registerForApplicationLifecycleNotifications()
        registerForActivityTypeNotifications()
        registerForThemeChanges()
        configureTimerPersistence()

        if let initialActivityType {
            didPromptForInitialActivityType = true
            appendTimerControlsView(
                activityType: initialActivityType,
                autoStart: shouldAutoStartInitialActivityType
            )
            shouldAutoStartInitialActivityType = false
        }

#if DEBUG
        appendScreenshotSampleTimerControlsIfNeeded()
#endif
    }

    private func registerForApplicationLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    private func registerForActivityTypeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activityTypeDidPersist),
            name: TimerSessionState.didPersistActivityNotification,
            object: nil
        )
    }

    private func registerForThemeChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: AppTheme.didChangeNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        refreshDisplayedTimers()
    }

    @objc private func applicationDidEnterBackground() {
        refreshDisplayedTimers()
        checkpointTimerCaches()
    }

    @objc private func activityTypeDidPersist(_ notification: Notification) {
        guard
            let activityTypeID = notification.userInfo?[TimerSessionState.activityTypeIDUserInfoKey] as? UUID,
            let activityType = activityType(activityTypeID: activityTypeID)
        else {
            return
        }

        refreshActivityTypeName(activityType)
    }

    @objc private func themeDidChange() {
        applyTheme()
        publishLiveActivityFontChange()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        refreshDisplayedTimers()
        removeExpiredInactiveTimerControls()
        promptForInitialActivityTypeIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            TimerSessionState.notifyTimerViewControllerDismissed()
        }
    }

    private func configureAppearance() {
        title = "Timers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Activity Types",
            style: .plain,
            target: self,
            action: #selector(activityTypesButtonTapped)
        )

        applyTheme()

        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        timerControlsStackView.axis = .vertical
        timerControlsStackView.spacing = 28
        timerControlsStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(timerControlsStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            timerControlsStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 5),
            timerControlsStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            timerControlsStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            timerControlsStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            timerControlsStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
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
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .regular)
        ]
        buttonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: AppTheme.metadataText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .regular)
        ]
        buttonAppearance.disabled.titleTextAttributes = [
            .foregroundColor: AppTheme.metadataText,
            .font: AppTheme.roundedFont(ofSize: 17, weight: .regular)
        ]
        appearance.buttonAppearance = buttonAppearance
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

    private func configureTimerPersistence() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        restoreTimerControlsFromCacheIfNeeded()
        scheduleTimerCacheCheckpoint()
    }

    private func hasRunningOrPausedTimer(activityTypeID: UUID) -> Bool {
        timerState(activityTypeID: activityTypeID) != .none
    }

    private func hasActiveOrRecentTimerControls() -> Bool {
        removeExpiredInactiveTimerControls()
        return !timerControlsViews.isEmpty
    }

    private func secondsUntilNextInactiveTimerControlsExpiration() -> TimeInterval? {
        removeExpiredInactiveTimerControls()

        let nextExpirationDate = timerControlsViews
            .filter { !$0.hasActiveTimer }
            .compactMap { timerControlsView in
                timerControlsView.latestCurrentSessionCompletionDate?
                    .addingTimeInterval(Self.inactiveTimerControlsRetentionInterval)
            }
            .min()

        return nextExpirationDate.map { max($0.timeIntervalSinceNow, 0) }
    }

    private func timerState(activityTypeID: UUID) -> ActivityTimerState {
        removeExpiredInactiveTimerControls()

        return timerControlsViews.first {
            $0.activityTypeID == activityTypeID
        }?.activityTimerState ?? .none
    }

    func configure(activityType: ActivityType, autoStart: Bool = false) {
        if let existingTimerControlsView = reusableTimerControlsView(activityType: activityType) {
            scrollToTimerControlsView(existingTimerControlsView)
            if autoStart {
                existingTimerControlsView.startIfNeeded()
            }
            return
        }

        initialActivityType = activityType
        shouldAutoStartInitialActivityType = autoStart

        if isViewLoaded {
            didPromptForInitialActivityType = true
            appendTimerControlsView(activityType: activityType, autoStart: autoStart)
            shouldAutoStartInitialActivityType = false
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

    private func appendTimerControlsView(activityType: ActivityType, autoStart: Bool = false) {
        removeExpiredInactiveTimerControls()

        let activity = makeTimerActivity(activityType: activityType)
        let timerControlsView = makeTimerControlsView(activity: activity)

        timerControlsStackView.insertArrangedSubview(timerControlsView, at: 0)
        timerControlsViews.insert(timerControlsView, at: 0)
        scrollToTimerControlsView(timerControlsView)

        if autoStart {
            timerControlsView.startIfNeeded()
        }
    }

    private func appendRestoredTimerControlsView(
        activityType: ActivityType,
        cache: ActivityTimerCache
    ) {
        let restoredState = RestoredTimerControlsState(
            startTime: cache.startTime,
            timeElapsed: cache.timeElapsed,
            isRunning: cache.isRunning,
            lastUpdateTime: cache.lastUpdateTime
        )
        let timerControlsView = appendRestoredTimerControlsView(
            activityType: activityType,
            restoredState: restoredState
        )
        updateTimerCache(from: timerControlsView, isRunning: cache.isRunning)
        restoreLiveActivity(from: timerControlsView)
    }

    @discardableResult
    private func appendRestoredTimerControlsView(
        activityType: ActivityType,
        restoredState: RestoredTimerControlsState
    ) -> TimerControlsView {
        let activity = makeTimerActivity(activityType: activityType)
        let timerControlsView = makeTimerControlsView(
            activity: activity,
            restoredState: restoredState
        )

        timerControlsStackView.insertArrangedSubview(timerControlsView, at: 0)
        timerControlsViews.insert(timerControlsView, at: 0)
        return timerControlsView
    }

    private func makeTimerControlsView(
        activity: Activity,
        restoredState: RestoredTimerControlsState? = nil
    ) -> TimerControlsView {
        let timerControlsView = TimerControlsView(activity: activity, restoredState: restoredState)
        timerControlsView.translatesAutoresizingMaskIntoConstraints = false
        timerControlsView.onActivityStopped = { [weak self] activity in
            self?.applyFinalElapsedTime(to: activity)
            self?.deleteTimerCache(activityTypeID: activity.activityType.uniqueID)
            self?.endLiveActivity(activityTypeID: activity.activityType.uniqueID, elapsedTime: activity.timeTaken)
            self?.saveTimerActivity(activity)
        }
        timerControlsView.onTimerStarted = { [weak self] timerControlsView in
            self?.createOrReplaceTimerCache(from: timerControlsView)
            self?.startLiveActivity(from: timerControlsView)
        }
        timerControlsView.onTimerResumed = { [weak self] timerControlsView in
            self?.updateTimerCache(from: timerControlsView, isRunning: true)
            self?.resumeLiveActivity(from: timerControlsView)
        }
        timerControlsView.onTimerPaused = { [weak self] timerControlsView in
            self?.updateTimerCache(from: timerControlsView, isRunning: false)
            self?.pauseLiveActivity(from: timerControlsView)
        }
        return timerControlsView
    }

    private func startLiveActivity(from timerControlsView: TimerControlsView) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard let startTime = timerControlsView.activityStartTime else {
            return
        }

        do {
            try ChronomarkLiveActivityController.startActivity(
                activityTypeID: timerControlsView.activityTypeID,
                name: timerControlsView.activityTypeName,
                elapsedSeconds: 0,
                status: "Running",
                timerStartDate: startTime,
                relevanceScore: 100
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func restoreLiveActivity(from timerControlsView: TimerControlsView) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard timerControlsView.hasActiveTimer else {
            return
        }

        let elapsedTime = timerControlsView.activeElapsedTime
        let isRunning = timerControlsView.activityTimerState == .running

        do {
            try ChronomarkLiveActivityController.startOrUpdateActivity(
                activityTypeID: timerControlsView.activityTypeID,
                name: timerControlsView.activityTypeName,
                elapsedSeconds: Int(elapsedTime),
                status: isRunning ? "Running" : "Paused",
                timerStartDate: isRunning ? Date().addingTimeInterval(-elapsedTime) : nil,
                relevanceScore: isRunning ? 100 : 50
            )
        } catch {
            print("Failed to restore Live Activity: \(error)")
        }
    }

    private func resumeLiveActivity(from timerControlsView: TimerControlsView) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        let elapsedTime = timerControlsView.activeElapsedTime
        ChronomarkLiveActivityController.updateActivity(
            activityTypeID: timerControlsView.activityTypeID,
            name: timerControlsView.activityTypeName,
            elapsedSeconds: Int(elapsedTime),
            status: "Running",
            timerStartDate: Date().addingTimeInterval(-elapsedTime)
        )
    }

    private func pauseLiveActivity(from timerControlsView: TimerControlsView) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        ChronomarkLiveActivityController.updateActivity(
            activityTypeID: timerControlsView.activityTypeID,
            name: timerControlsView.activityTypeName,
            elapsedSeconds: Int(timerControlsView.activeElapsedTime),
            status: "Paused",
            timerStartDate: nil,
            relevanceScore: 50
        )
    }

    private func endLiveActivity(activityTypeID: UUID, elapsedTime: TimeInterval?) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        ChronomarkLiveActivityController.endActivity(
            activityTypeID: activityTypeID,
            elapsedSeconds: Int(elapsedTime ?? 0)
        )
    }

    private func updateLiveActivityName(
        from timerControlsView: TimerControlsView,
        name: String
    ) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard timerControlsView.hasActiveTimer else {
            return
        }

        let elapsedTime = timerControlsView.activeElapsedTime
        let isRunning = timerControlsView.activityTimerState == .running
        ChronomarkLiveActivityController.updateActivity(
            activityTypeID: timerControlsView.activityTypeID,
            name: name,
            elapsedSeconds: Int(elapsedTime),
            status: isRunning ? "Running" : "Paused",
            timerStartDate: isRunning ? Date().addingTimeInterval(-elapsedTime) : nil,
            relevanceScore: isRunning ? 100 : 50
        )
    }

    private func publishLiveActivityFontChange() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        for timerControlsView in timerControlsViews where timerControlsView.hasActiveTimer {
            let elapsedTime = timerControlsView.activeElapsedTime
            let isRunning = timerControlsView.activityTimerState == .running
            ChronomarkLiveActivityController.updateActivity(
                activityTypeID: timerControlsView.activityTypeID,
                name: timerControlsView.activityTypeName,
                elapsedSeconds: Int(elapsedTime),
                status: isRunning ? "Running" : "Paused",
                timerStartDate: isRunning ? Date().addingTimeInterval(-elapsedTime) : nil,
                relevanceScore: isRunning ? 100 : 50
            )
        }
    }

    private func reusableTimerControlsView(activityType: ActivityType) -> TimerControlsView? {
        removeExpiredInactiveTimerControls()

        return timerControlsViews.first {
            $0.activityTypeID == activityType.uniqueID
        }
    }

    private func activityType(activityTypeID: UUID) -> ActivityType? {
#if DEBUG
        if isUsingScreenshotSamples {
            return screenshotSampleActivityTypes.first { $0.uniqueID == activityTypeID }
        }
#endif
        guard let modelContext else {
            return nil
        }

        do {
            var descriptor = FetchDescriptor<ActivityType>(
                predicate: #Predicate { activityType in
                    activityType.uniqueID == activityTypeID
                }
            )
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        } catch {
            assertionFailure("Unable to fetch activity type: \(error)")
            return nil
        }
    }

    private func refreshActivityTypeName(_ activityType: ActivityType) {
        for timerControlsView in timerControlsViews where timerControlsView.activityTypeID == activityType.uniqueID {
            timerControlsView.updateActivityTypeName(activityType.name)
            updateLiveActivityName(from: timerControlsView, name: activityType.name)
        }
    }

    private func scrollToTimerControlsView(_ timerControlsView: TimerControlsView) {
        view.layoutIfNeeded()

        let targetRect = timerControlsView.convert(timerControlsView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(targetRect.insetBy(dx: 0, dy: -24), animated: true)
    }

    private func removeExpiredInactiveTimerControls() {
        let cutoffDate = Date().addingTimeInterval(-Self.inactiveTimerControlsRetentionInterval)
        let expiredTimerControlsViews = timerControlsViews.filter { timerControlsView in
            guard
                !timerControlsView.hasActiveTimer,
                let latestCurrentSessionCompletionDate = timerControlsView.latestCurrentSessionCompletionDate
            else {
                return false
            }

            return latestCurrentSessionCompletionDate < cutoffDate
        }

        for timerControlsView in expiredTimerControlsViews {
            timerControlsStackView.removeArrangedSubview(timerControlsView)
            timerControlsView.removeFromSuperview()
        }

        timerControlsViews.removeAll { timerControlsView in
            expiredTimerControlsViews.contains { $0 === timerControlsView }
        }
    }

    private func removeTimerControlsView(activityTypeID: UUID) {
        guard let timerControlsView = timerControlsViews.first(where: { $0.activityTypeID == activityTypeID }) else {
            return
        }

        timerControlsStackView.removeArrangedSubview(timerControlsView)
        timerControlsView.removeFromSuperview()
        timerControlsViews.removeAll { $0 === timerControlsView }
        endLiveActivity(activityTypeID: activityTypeID, elapsedTime: timerControlsView.activeElapsedTime)
        deleteTimerCache(activityTypeID: activityTypeID)
        TimerSessionState.notifyActiveTimersChanged()
    }

    private func promptForInitialActivityTypeIfNeeded() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
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

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
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

    private func restoreTimerControlsFromCacheIfNeeded() {
        guard !didRestoreTimerCaches else {
            return
        }

        didRestoreTimerCaches = true

        guard let modelContext else {
            return
        }

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            let activityTypesByID = Dictionary(
                uniqueKeysWithValues: activityTypes.map { ($0.uniqueID, $0) }
            )
            let caches = try modelContext.fetch(FetchDescriptor<ActivityTimerCache>())
                .sorted { lhs, rhs in
                    lhs.lastUpdateTime > rhs.lastUpdateTime
            }
            var didMutateCaches = false
            var restoredCount = 0
            let restoreCutoffDate = Self.timerCacheRestoreCutoffDate()

            for cache in caches {
                guard cache.lastUpdateTime >= restoreCutoffDate else {
                    modelContext.delete(cache)
                    didMutateCaches = true
                    continue
                }

                guard let activityType = activityTypesByID[cache.activityTypeUniqueID] else {
                    modelContext.delete(cache)
                    didMutateCaches = true
                    continue
                }

                guard reusableTimerControlsView(activityType: activityType) == nil else {
                    continue
                }

                appendRestoredTimerControlsView(activityType: activityType, cache: cache)
                didMutateCaches = true
                restoredCount += 1
            }

            restoredTimerCacheCount = restoredCount

            if didMutateCaches {
                try modelContext.save()
                TimerSessionState.markTimerStarted()
                TimerSessionState.notifyActiveTimersChanged()
            }
        } catch {
            assertionFailure("Unable to restore cached timers: \(error)")
        }
    }

    private func scheduleTimerCacheCheckpoint() {
        timerCacheCheckpointTimer?.invalidate()
        timerCacheCheckpointTimer = Timer.scheduledTimer(
            withTimeInterval: Self.timerCacheCheckpointInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkpointTimerCaches()
        }
        timerCacheCheckpointTimer?.tolerance = 10
    }

    private func checkpointTimerCaches() {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        for timerControlsView in timerControlsViews where timerControlsView.hasActiveTimer {
            updateTimerCache(
                from: timerControlsView,
                isRunning: timerControlsView.activityTimerState == .running
            )
        }
    }

    private func refreshDisplayedTimers() {
        for timerControlsView in timerControlsViews {
            timerControlsView.refreshDisplayedElapsedTime()
        }
    }

    private func createOrReplaceTimerCache(from timerControlsView: TimerControlsView) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard
            let modelContext,
            let startTime = timerControlsView.activityStartTime
        else {
            return
        }

        deleteTimerCache(activityTypeID: timerControlsView.activityTypeID, shouldSave: false)

        let now = Date()
        let cache = ActivityTimerCache(
            activityTypeUniqueID: timerControlsView.activityTypeID,
            startTime: startTime,
            timeElapsed: 0,
            isRunning: true,
            lastUpdateTime: now
        )
        modelContext.insert(cache)
        saveTimerCacheChanges()
    }

    private func updateTimerCache(from timerControlsView: TimerControlsView, isRunning: Bool) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard
            let modelContext,
            let startTime = timerControlsView.activityStartTime
        else {
            return
        }

        let now = Date()
        let existingCache = timerCache(activityTypeID: timerControlsView.activityTypeID)
        let elapsedTime = elapsedTime(
            for: timerControlsView,
            existingCache: existingCache,
            now: now
        )
        let cache = existingCache ?? ActivityTimerCache(
            activityTypeUniqueID: timerControlsView.activityTypeID,
            startTime: startTime,
            timeElapsed: elapsedTime,
            isRunning: isRunning,
            lastUpdateTime: now
        )

        if existingCache == nil {
            modelContext.insert(cache)
        }

        cache.startTime = startTime
        cache.timeElapsed = elapsedTime
        cache.isRunning = isRunning
        cache.lastUpdateTime = now
        saveTimerCacheChanges()
    }

    private func elapsedTime(
        for timerControlsView: TimerControlsView,
        existingCache: ActivityTimerCache?,
        now: Date
    ) -> TimeInterval {
        guard let existingCache else {
            return timerControlsView.activeElapsedTime
        }

        guard existingCache.isRunning else {
            return existingCache.timeElapsed
        }

        return existingCache.timeElapsed + now.timeIntervalSince(existingCache.lastUpdateTime)
    }

    private func applyFinalElapsedTime(to activity: Activity) {
        guard let cache = timerCache(activityTypeID: activity.activityType.uniqueID) else {
            return
        }

        if cache.isRunning {
            activity.timeTaken = cache.timeElapsed + Date().timeIntervalSince(cache.lastUpdateTime)
        } else {
            activity.timeTaken = cache.timeElapsed
        }

        activity.activityStartTime = cache.startTime
    }

    private func deleteTimerCache(activityTypeID: UUID, shouldSave: Bool = true) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
        guard let modelContext else {
            return
        }

        let matchingCaches = timerCaches(activityTypeID: activityTypeID)
        for cache in matchingCaches {
            modelContext.delete(cache)
        }

        if shouldSave {
            saveTimerCacheChanges()
        }
    }

    private func timerCache(activityTypeID: UUID) -> ActivityTimerCache? {
        timerCaches(activityTypeID: activityTypeID).first
    }

    private func timerCaches(activityTypeID: UUID) -> [ActivityTimerCache] {
        guard let modelContext else {
            return []
        }

        do {
            return try modelContext.fetch(FetchDescriptor<ActivityTimerCache>())
                .filter { $0.activityTypeUniqueID == activityTypeID }
        } catch {
            assertionFailure("Unable to fetch timer cache: \(error)")
            return []
        }
    }

    private func saveTimerCacheChanges() {
        guard let modelContext else {
            return
        }

        do {
            try modelContext.save()
            TimerSessionState.notifyActiveTimersChanged()
        } catch {
            assertionFailure("Unable to save timer cache: \(error)")
        }
    }

    private func saveTimerActivity(_ activity: Activity) {
#if DEBUG
        guard !isUsingScreenshotSamples else {
            return
        }
#endif
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
            TimerSessionState.notifyActivityPersisted(activityTypeID: activity.activityType.uniqueID)
            removeExpiredInactiveTimerControls()
        } catch {
            modelContext.delete(activity)
            assertionFailure("Unable to save timer activity: \(error)")
        }
    }

#if DEBUG
    func configureForScreenshotSample(
        activityTypes: [ActivityType],
        timers: [ScreenshotSampleTimer]
    ) {
        isUsingScreenshotSamples = true
        didPromptForInitialActivityType = true
        didRestoreTimerCaches = true
        modelContext = nil
        screenshotSampleActivityTypes = activityTypes
        screenshotSampleTimers = timers

        if isViewLoaded {
            appendScreenshotSampleTimerControlsIfNeeded()
        }
    }

    static func setActiveScreenshotSampleController(
        _ timerViewController: TimerViewController,
        navigationController: UINavigationController
    ) {
        activeInstance = timerViewController
        activeNavigationController = navigationController
    }

    private func appendScreenshotSampleTimerControlsIfNeeded() {
        guard isUsingScreenshotSamples, timerControlsViews.isEmpty else {
            return
        }

        let activityTypesByID = Dictionary(
            uniqueKeysWithValues: screenshotSampleActivityTypes.map { ($0.uniqueID, $0) }
        )

        for timer in screenshotSampleTimers.reversed() {
            guard let activityType = activityTypesByID[timer.activityTypeID] else {
                continue
            }

            appendRestoredTimerControlsView(
                activityType: activityType,
                restoredState: timer.state
            )
        }

        TimerSessionState.markTimerStarted()
        TimerSessionState.notifyActiveTimersChanged()
    }
#endif
}

extension UIViewController {
    func presentTimerViewController(
        modelContext: ModelContext?,
        activityType: ActivityType? = nil,
        autoStart: Bool = false
    ) {
        if let timerViewController = TimerViewController.activeInstance,
           let navigationController = TimerViewController.activeNavigationController {
            timerViewController.modelContext = modelContext

            if let activityType {
                timerViewController.configure(activityType: activityType, autoStart: autoStart)
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
            timerViewController.configure(activityType: activityType, autoStart: autoStart)
        }

        let navigationController = UINavigationController(rootViewController: timerViewController)
        navigationController.modalPresentationStyle = .pageSheet
        TimerViewController.activeInstance = timerViewController
        TimerViewController.activeNavigationController = navigationController
        present(navigationController, animated: true)
    }
}
