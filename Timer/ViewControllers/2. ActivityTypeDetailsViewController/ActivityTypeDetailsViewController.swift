import UIKit

final class ActivityTypeDetailsViewController: UIViewController {
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

        timerLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .medium)
        timerLabel.textColor = .label
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.55

        var startConfiguration = UIButton.Configuration.filled()
        startConfiguration.title = "Start"
        startConfiguration.baseBackgroundColor = .systemBlue
        startConfiguration.baseForegroundColor = .white
        startConfiguration.cornerStyle = .large
        startConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        startButton.configuration = startConfiguration
        startButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .semibold)

        var stopConfiguration = UIButton.Configuration.tinted()
        stopConfiguration.title = "Stop"
        stopConfiguration.baseBackgroundColor = .systemRed
        stopConfiguration.baseForegroundColor = .systemRed
        stopConfiguration.cornerStyle = .large
        stopConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        stopButton.configuration = stopConfiguration
        stopButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .semibold)

        updateStartButtonTitle()
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

        startButton.configuration?.title = title

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
        timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
