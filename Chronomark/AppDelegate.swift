import UIKit
import SwiftData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: ActivityType.self,
                Activity.self,
                ActivityTag.self,
                ActivityTimerCache.self
            )
        } catch {
            fatalError("Unable to create SwiftData model container: \(error)")
        }
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppTheme.configureTypographyAppearance()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
