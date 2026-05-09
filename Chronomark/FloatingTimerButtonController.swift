import UIKit
import SwiftData

enum FloatingTimerButtonContext {
    case globalTimers
    case activityType(ActivityType)
}

protocol FloatingTimerButtonContextProviding: AnyObject {
    var floatingTimerButtonContext: FloatingTimerButtonContext? { get }
}

final class FloatingTimerButtonController: NSObject {
    private let containerView = UIView()
    private let currentTimersButton = UIButton(type: .system)
    private weak var navigationController: UINavigationController?
    private var modelContext: ModelContext?
    private var currentTimersButtonRefreshTimer: Timer?

    static func install(
        on navigationController: UINavigationController,
        modelContext: ModelContext?
    ) -> FloatingTimerButtonController {
        let floatingTimerButtonController = FloatingTimerButtonController()
        floatingTimerButtonController.modelContext = modelContext
        floatingTimerButtonController.attach(to: navigationController)
        return floatingTimerButtonController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        currentTimersButtonRefreshTimer?.invalidate()
    }

    private func attach(to navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.delegate = self

        configureContainerView()
        configureCurrentTimersButton()

        navigationController.view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 56),
            containerView.heightAnchor.constraint(equalToConstant: 56),
            containerView.trailingAnchor.constraint(equalTo: navigationController.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: navigationController.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        updateCurrentTimersButton()
    }

    private func configureContainerView() {
        containerView.backgroundColor = .clear
        containerView.isOpaque = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureCurrentTimersButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = AppTheme.accent
        configuration.baseForegroundColor = .white

        currentTimersButton.configuration = configuration
        currentTimersButton.layer.cornerRadius = 18
        currentTimersButton.layer.cornerCurve = .continuous
        currentTimersButton.clipsToBounds = true
        currentTimersButton.layer.shadowColor = UIColor.black.cgColor
        currentTimersButton.layer.shadowOpacity = 0.18
        currentTimersButton.layer.shadowRadius = 10
        currentTimersButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        currentTimersButton.translatesAutoresizingMaskIntoConstraints = false
        currentTimersButton.addAction(
            UIAction { [weak self] _ in
                self?.showTimerViewController()
            },
            for: .touchUpInside
        )

        containerView.addSubview(currentTimersButton)

        NSLayoutConstraint.activate([
            currentTimersButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            currentTimersButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            currentTimersButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            currentTimersButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerViewControllerDidDismiss),
            name: TimerSessionState.didDismissTimerViewControllerNotification,
            object: nil
        )
    }

    @objc private func timerSessionDidStartTimer() {
        updateCurrentTimersButtonAfterTimerStateChange()
    }

    @objc private func activeTimersDidChange() {
        updateCurrentTimersButtonAfterTimerStateChange()
    }

    @objc private func timerViewControllerDidDismiss() {
        updateCurrentTimersButtonAfterTimerStateChange()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updateCurrentTimersButton(hideWhenNoContext: false)
        }
    }

    private func updateCurrentTimersButtonAfterTimerStateChange() {
        updateCurrentTimersButton(hideWhenNoContext: false)

        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentTimersButton(hideWhenNoContext: false)
        }
    }

    private func updateCurrentTimersButton(hideWhenNoContext: Bool = true) {
        guard let context = currentContext() else {
            currentTimersButtonRefreshTimer?.invalidate()
            currentTimersButtonRefreshTimer = nil
            containerView.isHidden = true
            return
        }

        containerView.isHidden = false
        navigationController?.view.bringSubviewToFront(containerView)

        var configuration = currentTimersButton.configuration ?? UIButton.Configuration.filled()
        configuration.image = currentTimersButtonImage(for: context)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        configuration.baseBackgroundColor = currentTimersButtonBackgroundColor(for: context)
        configuration.baseForegroundColor = .white
        currentTimersButton.configuration = configuration
        currentTimersButton.accessibilityLabel = currentTimersButtonAccessibilityLabel(for: context)

        scheduleCurrentTimersButtonRefresh(for: context)
    }

    private func scheduleCurrentTimersButtonRefresh(for context: FloatingTimerButtonContext) {
        currentTimersButtonRefreshTimer?.invalidate()
        currentTimersButtonRefreshTimer = nil

        guard
            case .globalTimers = context,
            let interval = TimerViewController.secondsUntilNextInactiveTimerControlsExpiration()
        else {
            return
        }

        let refreshTimer = Timer(timeInterval: max(interval, 0.1), repeats: false) { [weak self] _ in
            self?.updateCurrentTimersButton(hideWhenNoContext: false)
        }
        refreshTimer.tolerance = 1
        RunLoop.main.add(refreshTimer, forMode: .common)
        currentTimersButtonRefreshTimer = refreshTimer
    }

    private func currentContext() -> FloatingTimerButtonContext? {
        let visibleViewController = navigationController?.visibleViewController
        return (visibleViewController as? FloatingTimerButtonContextProviding)?.floatingTimerButtonContext
    }

    private func currentTimersButtonImage(for context: FloatingTimerButtonContext) -> UIImage? {
        switch context {
        case .globalTimers:
            return UIImage(systemName: "timer")
        case let .activityType(activityType):
            switch TimerViewController.timerState(for: activityType) {
            case .none:
                return UIImage(systemName: "plus.circle.fill")
            case .running:
                return UIImage(systemName: "timer")
            case .paused:
                return UIImage(systemName: "pause.circle.fill")
            }
        }
    }

    private func currentTimersButtonBackgroundColor(for context: FloatingTimerButtonContext) -> UIColor {
        switch context {
        case .globalTimers:
            return AppTheme.accent
        case let .activityType(activityType):
            switch TimerViewController.timerState(for: activityType) {
            case .none, .running:
                return AppTheme.accent
            case .paused:
                return AppTheme.paused
            }
        }
    }

    private func currentTimersButtonAccessibilityLabel(for context: FloatingTimerButtonContext) -> String {
        switch context {
        case .globalTimers:
            return "Show current timers"
        case let .activityType(activityType):
            switch TimerViewController.timerState(for: activityType) {
            case .none:
                return "Record activity"
            case .running:
                return "Timer running"
            case .paused:
                return "Timer paused"
            }
        }
    }

    private func showTimerViewController() {
        guard let presentingViewController = navigationController?.visibleViewController else {
            return
        }

        switch currentContext() {
        case .globalTimers, .none:
            presentingViewController.presentTimerViewController(modelContext: modelContext)
        case let .activityType(activityType):
            presentingViewController.presentTimerViewController(
                modelContext: modelContext,
                activityType: activityType
            )
        }
    }
}

extension FloatingTimerButtonController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateCurrentTimersButton()
    }
}
