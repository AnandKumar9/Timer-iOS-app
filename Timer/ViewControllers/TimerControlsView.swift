import UIKit

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

    private var timer: Timer?
    private var elapsedSeconds = 0
    private let activity: Activity
    private var timerState = TimerState.stopped
    var onActivityStopped: ((Activity) -> Void)?

    init(activity: Activity) {
        self.activity = activity
        super.init(frame: .zero)
        configureView()
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
        configureButtons()
        configureLayout()
        updateTimerLabel()
        updateStartButtonTitle()
    }

    private func configureActivityTypeNameLabel() {
        activityTypeNameLabel.text = activity.activityType.name
        activityTypeNameLabel.font = .systemFont(ofSize: 25, weight: .semibold)
        activityTypeNameLabel.textColor = .label
        activityTypeNameLabel.textAlignment = .center
        activityTypeNameLabel.numberOfLines = 2
        activityTypeNameLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTimerLabel() {
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 56, weight: .regular)
        timerLabel.textColor = .label
        timerLabel.textAlignment = .center
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.7
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureButtons() {
        configureButton(
            startButton,
            backgroundColor: .systemBlue.withAlphaComponent(0.12),
            foregroundColor: .systemBlue
        )
        configureButton(
            stopButton,
            backgroundColor: .systemGray5,
            foregroundColor: .systemRed
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
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
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

    @objc private func startButtonTapped() {
        switch timerState {
        case .running:
            pauseTimer()
        case .stopped, .paused:
            startTimer()
        }
    }

    @objc private func stopButtonTapped() {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        timerState = .stopped
        updateStartButtonTitle()
        updateTimerLabel()

        activity.activityCompletionTime = Date()
        onActivityStopped?(activity)
    }

    private func startTimer() {
        if timerState == .stopped {
            activity.activityStartTime = Date()
            activity.activityCompletionTime = nil
        }

        timerState = .running
        updateStartButtonTitle()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .paused
        updateStartButtonTitle()
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

        let shouldEnableStopButton = timerState != .stopped
        stopButton.isEnabled = shouldEnableStopButton
        stopButton.alpha = shouldEnableStopButton ? 1.0 : 0.45
    }

    private func tick() {
        elapsedSeconds += 1
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
    }
}
