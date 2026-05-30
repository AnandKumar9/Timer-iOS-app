import UIKit
import SwiftData

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var modelContext: ModelContext?
    private var floatingTimerButtonController: FloatingTimerButtonController?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
#if DEBUG
        if ScreenshotSampleCoordinator.isEnabled {
            let navigationController = ScreenshotSampleCoordinator.makeInitialNavigationController()
            floatingTimerButtonController = ScreenshotSampleCoordinator.installFloatingTimerButton(
                on: navigationController
            )
            window.rootViewController = navigationController
            AppAppearanceController.applySavedAppearance(to: window)
            window.makeKeyAndVisible()

            self.window = window
            self.modelContext = nil
            return
        }
#endif
        let modelContext = (UIApplication.shared.delegate as? AppDelegate)?.modelContainer.mainContext
        let restoredTimerCount = TimerViewController.restoreCachedTimersIfNeeded(modelContext: modelContext)
        let shouldOpenTimerViewController = containsTimerURL(connectionOptions.urlContexts)
        let navigationController = UINavigationController(
            rootViewController: makeInitialViewController(modelContext: modelContext)
        )
        floatingTimerButtonController = FloatingTimerButtonController.install(
            on: navigationController,
            modelContext: modelContext
        )
        window.rootViewController = navigationController
        AppAppearanceController.applySavedAppearance(to: window)
        window.makeKeyAndVisible()

        self.window = window
        self.modelContext = modelContext

        if shouldOpenTimerViewController {
            DispatchQueue.main.async { [weak self] in
                self?.presentTimerViewController()
            }
        } else {
            presentRestoredTimersAlertIfNeeded(
                restoredTimerCount: restoredTimerCount,
                on: navigationController
            )
        }

    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard containsTimerURL(URLContexts) else {
            return
        }

        presentTimerViewController()
    }

    private func containsTimerURL(_ URLContexts: Set<UIOpenURLContext>) -> Bool {
        URLContexts.contains { urlContext in
            urlContext.url.scheme == "chronomark" && urlContext.url.host == "timer"
        }
    }

    private func makeInitialViewController(modelContext: ModelContext?) -> UIViewController {
        let activityTypesViewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        activityTypesViewController.modelContext = modelContext
        return activityTypesViewController
    }

    private func presentTimerViewController() {
        guard let rootViewController = window?.rootViewController else {
            return
        }

        topPresentedViewController(from: rootViewController)
            .presentTimerViewController(modelContext: modelContext)
    }

    private func topPresentedViewController(from viewController: UIViewController) -> UIViewController {
        var topViewController = viewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }

    private func presentRestoredTimersAlertIfNeeded(
        restoredTimerCount: Int,
        on navigationController: UINavigationController
    ) {
        guard restoredTimerCount > 0 else {
            return
        }

        guard AppSettings.alertWhenTimersRestored else {
            return
        }

        let timerText = restoredTimerCount == 1 ? "timer" : "timers"
        let alertController = UIAlertController(
            title: "Timers Restored",
            message: "We restored \(restoredTimerCount) \(timerText) from your last session.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))

        DispatchQueue.main.async {
            navigationController.present(alertController, animated: true)
        }
    }
}
