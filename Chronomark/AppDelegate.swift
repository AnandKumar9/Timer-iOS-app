import UIKit
import SwiftData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private static let singleCategoryMigrationCompletedKey = "ActivityTypeSingleCategoryMigration.completed"

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
        runSingleCategoryMigrationIfNeeded()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func runSingleCategoryMigrationIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.singleCategoryMigrationCompletedKey) else {
            return
        }

        let modelContext = modelContainer.mainContext

        do {
            let activityTypes = try modelContext.fetch(FetchDescriptor<ActivityType>())
            var didModifyActivityTypes = false

            activityTypes.forEach { activityType in
                guard let firstTag = activityType.tags?.first,
                      (activityType.tags?.count ?? 0) > 1
                else {
                    return
                }

                activityType.tags = [firstTag]
                didModifyActivityTypes = true
            }

            if didModifyActivityTypes {
                try modelContext.save()
            }

            UserDefaults.standard.set(true, forKey: Self.singleCategoryMigrationCompletedKey)
        } catch {
            assertionFailure("Unable to migrate activity types to single category: \(error)")
        }
    }
}
