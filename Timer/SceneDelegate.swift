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
        window.rootViewController = UINavigationController(
            rootViewController: makeInitialViewController(modelContext: modelContext)
        )
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
