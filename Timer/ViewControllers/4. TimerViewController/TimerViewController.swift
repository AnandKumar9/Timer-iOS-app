import UIKit

final class TimerViewController: UIViewController {
    private enum TimerState {
        case stopped
        case running
        case paused
    }

    @IBOutlet private weak var timerLabel: UILabel!
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!

    private var timer: Timer?
    private var elapsedSeconds = 0
    private var timerState = TimerState.stopped

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        updateTimerLabel()
    }

    deinit {
        timer?.invalidate()
    }

    @IBAction private func startButtonTapped(_ sender: UIButton) {
        switch timerState {
        case .stopped, .paused:
            startTimer()
        case .running:
            pauseTimer()
        }
    }

    @IBAction private func stopButtonTapped(_ sender: UIButton) {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        timerState = .stopped
        updateStartButtonTitle()
        updateTimerLabel()
    }

    private func startTimer() {
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

    private func configureAppearance() {
        view.backgroundColor = .systemBackground

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 56, weight: .regular)
        timerLabel.textColor = .label
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.7

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
        stopButton.setTitle("Stop", for: .normal)

        updateStartButtonTitle()
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
    }

    private func updateStartButtonTitle() {
        let title: String
        switch timerState {
        case .stopped:
            title = "Start"
        case .running:
            title = "Pause"
        case .paused:
            title = "Resume"
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
