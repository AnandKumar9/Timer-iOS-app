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
        TimerViewController.restoreCachedTimersIfNeeded(modelContext: modelContext)
        let navigationController = UINavigationController(
            rootViewController: makeInitialViewController(modelContext: modelContext)
        )
        floatingTimerButtonController = FloatingTimerButtonController.install(
            on: navigationController,
            modelContext: modelContext
        )
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.window = window
        self.modelContext = modelContext
    }

    private func makeInitialViewController(modelContext: ModelContext?) -> UIViewController {
        let activityTypesViewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        activityTypesViewController.modelContext = modelContext
        return activityTypesViewController
    }
}
