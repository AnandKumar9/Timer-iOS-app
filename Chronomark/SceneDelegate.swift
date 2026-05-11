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
        let modelContext = (UIApplication.shared.delegate as? AppDelegate)?.modelContainer.mainContext
        let restoredTimerCount = TimerViewController.restoreCachedTimersIfNeeded(modelContext: modelContext)
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

        presentRestoredTimersAlertIfNeeded(
            restoredTimerCount: restoredTimerCount,
            on: navigationController
        )
    }

    private func makeInitialViewController(modelContext: ModelContext?) -> UIViewController {
        let activityTypesViewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        activityTypesViewController.modelContext = modelContext
        return activityTypesViewController
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
