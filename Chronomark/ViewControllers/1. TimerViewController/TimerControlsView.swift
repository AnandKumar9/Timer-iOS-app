import UIKit

enum TimerSessionState {
    static let didStartTimerNotification = Notification.Name("TimerSessionState.didStartTimerNotification")
    static let didChangeActiveTimersNotification = Notification.Name("TimerSessionState.didChangeActiveTimersNotification")
    static let didPersistActivityNotification = Notification.Name("TimerSessionState.didPersistActivityNotification")
    static let didDismissTimerViewControllerNotification = Notification.Name("TimerSessionState.didDismissTimerViewControllerNotification")
    static let activityTypeIDUserInfoKey = "activityTypeID"
    private(set) static var hasStartedTimer = false

    static func markTimerStarted() {
        guard !hasStartedTimer else {
            return
        }

        hasStartedTimer = true
        NotificationCenter.default.post(name: didStartTimerNotification, object: nil)
    }

    static func notifyActiveTimersChanged() {
        NotificationCenter.default.post(name: didChangeActiveTimersNotification, object: nil)
    }

    static func notifyTimerViewControllerDismissed() {
        NotificationCenter.default.post(name: didDismissTimerViewControllerNotification, object: nil)
    }

    static func notifyActivityPersisted(activityTypeID: UUID) {
        NotificationCenter.default.post(
            name: didPersistActivityNotification,
            object: nil,
            userInfo: [activityTypeIDUserInfoKey: activityTypeID]
        )
    }
}

enum ActivityTimerState {
    case none
    case running
    case paused
}

struct RestoredTimerControlsState {
    let startTime: Date
    let timeElapsed: TimeInterval
    let isRunning: Bool
    let lastUpdateTime: Date
}

final class TimerControlsView: UIView {
    private enum TimerState {
        case running
        case paused
        case stopped
    }

    private let activityTypeNameLabel = UILabel()
    private let timerLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let contentStackView = UIStackView()
    private let buttonStackView = UIStackView()
    private let lastActivityRowView = UIView()
    private let lastActivityDateLabel = UILabel()
    private let lastActivityDurationLabel = UILabel()
    private let lastActivityNoteLabel = UILabel()
    private let addLastActivityNoteButton = UIButton(type: .system)

    private var timer: Timer?
    private var elapsedSeconds = 0
    private var activeTimeTaken: TimeInterval = 0
    private var runningElapsedReferenceTime: Date?
    private var activity: Activity
    private var timerState = TimerState.stopped
    private var latestCurrentSessionCompletionTime: Date?
    var onActivityStopped: ((Activity) -> Void)?
    var onTimerStarted: ((TimerControlsView) -> Void)?
    var onTimerResumed: ((TimerControlsView) -> Void)?
    var onTimerPaused: ((TimerControlsView) -> Void)?
    var onAddNoteTapped: ((Activity) -> Void)?
    var hasActiveTimer: Bool {
        timerState != .stopped
    }
    var activityTimerState: ActivityTimerState {
        switch timerState {
        case .running:
            return .running
        case .paused:
            return .paused
        case .stopped:
            return .none
        }
    }
    var activityTypeID: UUID {
        activity.activityType.uniqueID
    }
    var activityTypeName: String {
        activity.activityType.name
    }
    var hasStartedTimer: Bool {
        activity.activityStartTime != nil
    }
    var latestCurrentSessionCompletionDate: Date? {
        latestCurrentSessionCompletionTime
    }
    var activityStartTime: Date? {
        activity.activityStartTime
    }
    var activeElapsedTime: TimeInterval {
        refreshDisplayedElapsedTime()
        return activeTimeTaken
    }

    func updateActivityTypeName(_ name: String) {
        activityTypeNameLabel.text = name
        updateLastActivityRow()
    }

    func refreshLastActivityRow() {
        updateLastActivityRow()
    }

    func startIfNeeded() {
        guard timerState == .stopped else {
            return
        }

        startTimer()
    }

    init(activity: Activity, restoredState: RestoredTimerControlsState? = nil) {
        self.activity = activity
        super.init(frame: .zero)
        configureView()
        configureSettingsNotifications()

        if let restoredState {
            restoreTimerState(restoredState)
        }
    }

    @available(*, unavailable, message: "Use init(activity:) instead.")
    override init(frame: CGRect) {
        fatalError("Use init(activity:) instead.")
    }

    @available(*, unavailable, message: "Use init(activity:) instead.")
    required init?(coder: NSCoder) {
        fatalError("Use init(activity:) instead.")
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func configureView() {
        configureActivityTypeNameLabel()
        configureTimerLabel()
        configureLastActivityRow()
        configureButtons()
        configureLayout()
        updateTimerLabel()
        updateLastActivityRow()
        updateStartButtonTitle()
    }

    private func configureSettingsNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(durationDisplayDidChange),
            name: AppSettings.durationDisplayDidChangeNotification,
            object: nil
        )
    }

    private func configureActivityTypeNameLabel() {
        activityTypeNameLabel.text = activity.activityType.name
        activityTypeNameLabel.font = AppTheme.roundedFont(ofSize: 25, weight: .semibold)
        activityTypeNameLabel.textColor = AppTheme.primaryText
        activityTypeNameLabel.textAlignment = .center
        activityTypeNameLabel.numberOfLines = 2
        activityTypeNameLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTimerLabel() {
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 56, weight: .regular)
        timerLabel.textColor = AppTheme.durationText
        timerLabel.textAlignment = .center
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.7
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureLastActivityRow() {
        lastActivityDateLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .regular)
        lastActivityDateLabel.textColor = AppTheme.metadataText
        lastActivityDateLabel.numberOfLines = 1

        lastActivityDurationLabel.font = AppTheme.roundedFont(ofSize: 15, weight: .medium)
        lastActivityDurationLabel.textColor = AppTheme.durationText
        lastActivityDurationLabel.textAlignment = .right
        lastActivityDurationLabel.numberOfLines = 1
        lastActivityDurationLabel.setContentHuggingPriority(.required, for: .horizontal)
        lastActivityDurationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        lastActivityNoteLabel.font = AppTheme.roundedFont(ofSize: 13, weight: .regular)
        lastActivityNoteLabel.textColor = AppTheme.metadataText
        lastActivityNoteLabel.numberOfLines = 1
        lastActivityNoteLabel.lineBreakMode = .byTruncatingTail

        var addNoteConfiguration = UIButton.Configuration.plain()
        addNoteConfiguration.image = UIImage(systemName: "plus.bubble")
        addNoteConfiguration.baseForegroundColor = AppTheme.accent
        addNoteConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        addNoteConfiguration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        addLastActivityNoteButton.configuration = addNoteConfiguration
        addLastActivityNoteButton.accessibilityLabel = "Add note to last activity"
        addLastActivityNoteButton.setContentHuggingPriority(.required, for: .horizontal)
        addLastActivityNoteButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addLastActivityNoteButton.addAction(
            UIAction { [weak self] _ in
                guard let self, let lastActivity = self.latestCompletedActivity() else {
                    return
                }

                self.onAddNoteTapped?(lastActivity)
            },
            for: .touchUpInside
        )

        let summaryStackView = UIStackView(arrangedSubviews: [
            lastActivityDateLabel,
            lastActivityDurationLabel,
            addLastActivityNoteButton
        ])
        summaryStackView.axis = .horizontal
        summaryStackView.alignment = .center
        summaryStackView.spacing = 8

        let stackView = UIStackView(arrangedSubviews: [summaryStackView, lastActivityNoteLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false

        lastActivityRowView.addSubview(stackView)
        lastActivityRowView.isHidden = true
        lastActivityRowView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: lastActivityRowView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: lastActivityRowView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: lastActivityRowView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: lastActivityRowView.bottomAnchor)
        ])
    }

    private func configureButtons() {
        configureButton(
            startButton,
            backgroundColor: AppTheme.accent.withAlphaComponent(0.14),
            foregroundColor: AppTheme.accent
        )
        configureButton(
            stopButton,
            backgroundColor: AppTheme.cardBackground,
            foregroundColor: AppTheme.destructive
        )

        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        stopButton.setTitle("Stop", for: .normal)
    }

    private func configureButton(
        _ button: UIButton,
        backgroundColor: UIColor,
        foregroundColor: UIColor
    ) {
        button.configuration = nil
        button.backgroundColor = backgroundColor
        button.setTitleColor(foregroundColor, for: .normal)
        button.titleLabel?.font = AppTheme.roundedFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 10
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureLayout() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        buttonStackView.addArrangedSubview(startButton)
        buttonStackView.addArrangedSubview(stopButton)

        contentStackView.addArrangedSubview(activityTypeNameLabel)
        contentStackView.addArrangedSubview(timerLabel)
        contentStackView.addArrangedSubview(buttonStackView)
        contentStackView.addArrangedSubview(lastActivityRowView)
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityTypeNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            timerLabel.heightAnchor.constraint(equalToConstant: 72),
            buttonStackView.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func restoreTimerState(_ restoredState: RestoredTimerControlsState) {
        let restoredElapsedTime: TimeInterval
        if restoredState.isRunning {
            restoredElapsedTime = restoredState.timeElapsed + Date().timeIntervalSince(restoredState.lastUpdateTime)
        } else {
            restoredElapsedTime = restoredState.timeElapsed
        }

        activeTimeTaken = max(0, restoredElapsedTime)
        elapsedSeconds = Int(activeTimeTaken)
        activity.activityStartTime = restoredState.startTime
        activity.activityCompletionTime = nil
        activity.timeTaken = nil
        timerState = restoredState.isRunning ? .running : .paused
        runningElapsedReferenceTime = restoredState.isRunning ? Date() : nil

        updateStartButtonTitle()
        updateTimerLabel()

        guard restoredState.isRunning else {
            return
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    @objc private func startButtonTapped() {
        switch timerState {
        case .running:
            pauseTimer()
        case .stopped, .paused:
            startTimer()
        }
    }

    @objc private func stopButtonTapped() {
        refreshDisplayedElapsedTime()
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        runningElapsedReferenceTime = nil
        timerState = .stopped

        let completionTime = Date()
        activity.activityCompletionTime = completionTime
        activity.timeTaken = activeTimeTaken
        latestCurrentSessionCompletionTime = completionTime
        onActivityStopped?(activity)
        activity = Activity(activityType: activity.activityType)
        updateLastActivityRow()
        updateStartButtonTitle()
        updateTimerLabel()
        TimerSessionState.notifyActiveTimersChanged()
    }

    private func startTimer() {
        TimerSessionState.markTimerStarted()

        let wasStopped = timerState == .stopped

        if timerState == .stopped {
            activeTimeTaken = 0
            elapsedSeconds = 0
            activity.activityStartTime = Date()
            activity.activityCompletionTime = nil
            activity.timeTaken = nil
        }

        timerState = .running
        runningElapsedReferenceTime = Date()
        updateStartButtonTitle()
        updateTimerLabel()
        if wasStopped {
            onTimerStarted?(self)
        } else {
            onTimerResumed?(self)
        }
        TimerSessionState.notifyActiveTimersChanged()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func pauseTimer() {
        refreshDisplayedElapsedTime()
        timer?.invalidate()
        timer = nil
        runningElapsedReferenceTime = nil
        timerState = .paused
        updateStartButtonTitle()
        updateTimerLabel()
        onTimerPaused?(self)
        TimerSessionState.notifyActiveTimersChanged()
    }

    private func updateStartButtonTitle() {
        let title: String
        switch timerState {
        case .running:
            title = "Pause"
        case .paused:
            title = "Resume"
        case .stopped:
            title = "Start"
        }

        startButton.setTitle(title, for: .normal)
        startButton.isEnabled = true
        startButton.alpha = 1.0
        startButton.backgroundColor = timerState == .running
            ? AppTheme.paused.withAlphaComponent(0.22)
            : AppTheme.accent.withAlphaComponent(0.14)
        startButton.setTitleColor(AppTheme.primaryText, for: .normal)

        let shouldEnableStopButton = timerState != .stopped
        stopButton.isEnabled = shouldEnableStopButton
        stopButton.alpha = shouldEnableStopButton ? 1.0 : 0.45
    }

    private func tick() {
        refreshDisplayedElapsedTime()
    }

    func refreshDisplayedElapsedTime() {
        guard
            timerState == .running,
            let runningElapsedReferenceTime
        else {
            return
        }

        let now = Date()
        activeTimeTaken += max(0, now.timeIntervalSince(runningElapsedReferenceTime))
        elapsedSeconds = Int(activeTimeTaken)
        self.runningElapsedReferenceTime = now
        updateTimerLabel()
    }

    private func updateTimerLabel() {
        let hours = elapsedSeconds / 3_600
        let minutes = (elapsedSeconds % 3_600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
        switch timerState {
        case .running:
            timerLabel.textColor = AppTheme.runningDigitText
        case .paused:
            timerLabel.textColor = AppTheme.paused
        case .stopped:
            timerLabel.textColor = AppTheme.durationText
        }
    }

    private func updateLastActivityRow() {
        guard
            let lastActivity = latestCompletedActivity(),
            let startTime = lastActivity.activityStartTime
        else {
            lastActivityRowView.isHidden = true
            return
        }

        lastActivityDateLabel.text = "Last: \(formattedDate(startTime))"
        lastActivityDurationLabel.text = formattedDuration(for: lastActivity)
        if let note = noteText(for: lastActivity) {
            lastActivityNoteLabel.text = note
            lastActivityNoteLabel.isHidden = false
            addLastActivityNoteButton.isHidden = true
        } else {
            lastActivityNoteLabel.text = nil
            lastActivityNoteLabel.isHidden = true
            addLastActivityNoteButton.isHidden = false
        }
        lastActivityRowView.isHidden = false
    }

    @objc private func durationDisplayDidChange() {
        updateLastActivityRow()
    }

    private func latestCompletedActivity() -> Activity? {
        activity.activityType.activities
            .filter { $0.activityStartTime != nil && $0.activityCompletionTime != nil }
            .sorted(by: activityStartSort)
            .first
    }

    private func activityStartSort(_ lhs: Activity, _ rhs: Activity) -> Bool {
        guard let lhsStartTime = lhs.activityStartTime else {
            return false
        }

        guard let rhsStartTime = rhs.activityStartTime else {
            return true
        }

        return lhsStartTime > rhsStartTime
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (EEE), hh:mm a"
        return formatter.string(from: date)
    }

    private func formattedDuration(for activity: Activity) -> String {
        let duration: TimeInterval

        if let timeTaken = activity.timeTaken {
            duration = timeTaken
        } else if
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime {
            duration = completionTime.timeIntervalSince(startTime)
        } else {
            duration = 0
        }

        return ActivityDisplayFormatter.roundedHistoryDurationText(for: duration)
    }

    private func noteText(for activity: Activity) -> String? {
        guard let note = activity.activityNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty
        else {
            return nil
        }

        return note
    }
}
