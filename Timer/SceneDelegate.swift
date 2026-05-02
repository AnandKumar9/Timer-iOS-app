import UIKit
import SwiftData

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var modelContext: ModelContext?

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
        let timerViewController = TimerViewController(
            nibName: "TimerViewController",
            bundle: nil
        )
        timerViewController.modelContext = modelContext
        window.rootViewController = timerViewController
        window.makeKeyAndVisible()

        self.window = window
        self.modelContext = modelContext
    }
}
