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

    init(activity: Activity, restoredState: RestoredTimerControlsState? = nil) {
        self.activity = activity
        super.init(frame: .zero)
        configureView()

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

        let stackView = UIStackView(arrangedSubviews: [lastActivityDateLabel, lastActivityDurationLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
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
            ? AppTheme.paused.withAlphaComponent(0.18)
            : AppTheme.accent.withAlphaComponent(0.14)
        startButton.setTitleColor(timerState == .running ? AppTheme.paused : AppTheme.accent, for: .normal)

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
        timerLabel.textColor = timerState == .running ? AppTheme.runningDigitText : AppTheme.durationText
    }

    private func updateLastActivityRow() {
        guard
            let lastActivity = latestCompletedActivity(),
            let completionTime = lastActivity.activityCompletionTime
        else {
            lastActivityRowView.isHidden = true
            return
        }

        lastActivityDateLabel.text = "Last: \(formattedDate(completionTime))"
        lastActivityDurationLabel.text = formattedDuration(for: lastActivity)
        lastActivityRowView.isHidden = false
    }

    private func latestCompletedActivity() -> Activity? {
        activity.activityType.activities
            .filter { $0.activityCompletionTime != nil }
            .sorted(by: activityCompletionSort)
            .first
    }

    private func activityCompletionSort(_ lhs: Activity, _ rhs: Activity) -> Bool {
        guard let lhsCompletionTime = lhs.activityCompletionTime else {
            return false
        }

        guard let rhsCompletionTime = rhs.activityCompletionTime else {
            return true
        }

        return lhsCompletionTime > rhsCompletionTime
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (EEE), hh:mm a"
        return formatter.string(from: date)
    }

    private func formattedDuration(for activity: Activity) -> String {
        let duration: Int

        if let timeTaken = activity.timeTaken {
            duration = max(0, Int(timeTaken))
        } else if
            let startTime = activity.activityStartTime,
            let completionTime = activity.activityCompletionTime {
            duration = max(0, Int(completionTime.timeIntervalSince(startTime)))
        } else {
            duration = 0
        }

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
}
