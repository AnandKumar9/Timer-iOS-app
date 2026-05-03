import UIKit
import SwiftData

final class ActivityDetailsViewController: UIViewController {
    private let currentTimersButton = UIButton(type: .system)

    var modelContext: ModelContext?
    var activity: Activity?

    private var activityType: ActivityType? {
        activity?.activityType
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateCurrentTimersButton()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAppearance() {
        title = "Activity Details"
        view.backgroundColor = .systemBackground

        configureCurrentTimersButton()

        currentTimersButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentTimersButton)

        NSLayoutConstraint.activate([
            currentTimersButton.widthAnchor.constraint(equalToConstant: 56),
            currentTimersButton.heightAnchor.constraint(equalToConstant: 56),
            currentTimersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            currentTimersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func configureCurrentTimersButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white

        currentTimersButton.configuration = configuration
        currentTimersButton.layer.cornerRadius = 18
        currentTimersButton.layer.cornerCurve = .continuous
        currentTimersButton.clipsToBounds = true
        currentTimersButton.addAction(
            UIAction { [weak self] _ in
                self?.showTimerViewController()
            },
            for: .touchUpInside
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerSessionDidStartTimer),
            name: TimerSessionState.didStartTimerNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeTimersDidChange),
            name: TimerSessionState.didChangeActiveTimersNotification,
            object: nil
        )
        updateCurrentTimersButton()
    }

    @objc private func timerSessionDidStartTimer() {
        updateCurrentTimersButton()
    }

    @objc private func activeTimersDidChange() {
        updateCurrentTimersButton()
    }

    private func updateCurrentTimersButton() {
        var configuration = currentTimersButton.configuration ?? UIButton.Configuration.filled()
        configuration.image = currentTimersButtonImage()
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        configuration.baseBackgroundColor = currentTimersButtonBackgroundColor()
        configuration.baseForegroundColor = .white
        currentTimersButton.configuration = configuration
        currentTimersButton.accessibilityLabel = currentTimersButtonAccessibilityLabel()
    }

    private func currentTimersButtonImage() -> UIImage? {
        guard let activityType else {
            return UIImage(systemName: "plus.circle.fill")
        }

        switch TimerViewController.timerState(for: activityType) {
        case .none:
            return UIImage(systemName: "plus.circle.fill")
        case .running:
            return UIImage(systemName: "timer")
        case .paused:
            return UIImage(systemName: "pause.circle.fill")
        }
    }

    private func currentTimersButtonBackgroundColor() -> UIColor {
        guard let activityType else {
            return .systemBlue
        }

        switch TimerViewController.timerState(for: activityType) {
        case .none, .running:
            return .systemBlue
        case .paused:
            return .systemOrange
        }
    }

    private func currentTimersButtonAccessibilityLabel() -> String {
        guard let activityType else {
            return "Record activity"
        }

        switch TimerViewController.timerState(for: activityType) {
        case .none:
            return "Record activity"
        case .running:
            return "Timer running"
        case .paused:
            return "Timer paused"
        }
    }

    private func showTimerViewController() {
        presentTimerViewController(modelContext: modelContext, activityType: activityType)
    }
}
