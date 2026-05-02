import UIKit
import SwiftData

final class ActivityDetailsViewController: UIViewController {
    private let detailLabel = UILabel()
    private let currentTimersButton = UIButton(type: .system)

    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateCurrentTimersButtonVisibility()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureAppearance() {
        title = "Activity Details"
        view.backgroundColor = .systemBackground

        configureDetailLabel()
        configureCurrentTimersButton()

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimersButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailLabel)
        view.addSubview(currentTimersButton)

        NSLayoutConstraint.activate([
            detailLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            detailLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            currentTimersButton.widthAnchor.constraint(equalToConstant: 56),
            currentTimersButton.heightAnchor.constraint(equalToConstant: 56),
            currentTimersButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            currentTimersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func configureDetailLabel() {
        detailLabel.text = "ActivityDetails"
        detailLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        detailLabel.textColor = .label
        detailLabel.textAlignment = .center
    }

    private func configureCurrentTimersButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "timer")
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white

        currentTimersButton.configuration = configuration
        currentTimersButton.layer.cornerRadius = 18
        currentTimersButton.layer.cornerCurve = .continuous
        currentTimersButton.clipsToBounds = true
        currentTimersButton.isHidden = !TimerSessionState.hasStartedTimer
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
    }

    @objc private func timerSessionDidStartTimer() {
        updateCurrentTimersButtonVisibility()
    }

    private func updateCurrentTimersButtonVisibility() {
        currentTimersButton.isHidden = !TimerSessionState.hasStartedTimer
    }

    private func showTimerViewController() {
        presentTimerViewController(modelContext: modelContext)
    }
}
