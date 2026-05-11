#if DEBUG
import UIKit
import SwiftData

enum ScreenshotSampleCoordinator {
    private static let sampleDataArgument = "--screenshot-sample-data"
    private static let screenArgumentPrefix = "--screenshot-screen="

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(sampleDataArgument)
    }

    static var requestedScreen: ScreenshotSampleScreen {
        let arguments = ProcessInfo.processInfo.arguments
        guard
            let screenArgument = arguments.first(where: { $0.hasPrefix(screenArgumentPrefix) }),
            let screen = ScreenshotSampleScreen(
                rawValue: String(screenArgument.dropFirst(screenArgumentPrefix.count))
            )
        else {
            return .activityTypes
        }

        return screen
    }

    static func makeInitialNavigationController() -> UINavigationController {
        let sampleData = ScreenshotSampleDataLoader.load()

        switch requestedScreen {
        case .activityTypes:
            return UINavigationController(
                rootViewController: makeActivityTypesViewController(sampleData: sampleData)
            )
        case .activityTypesFiltered:
            return UINavigationController(
                rootViewController: makeFilteredActivityTypesViewController(sampleData: sampleData)
            )
        case .activityHistory:
            return UINavigationController(
                rootViewController: makeActivityHistoryViewController(sampleData: sampleData)
            )
        case .activityDetails:
            return UINavigationController(
                rootViewController: makeActivityDetailsViewController(sampleData: sampleData)
            )
        case .timers:
            let timerViewController = makeTimerViewController(sampleData: sampleData)
            let navigationController = UINavigationController(rootViewController: timerViewController)
            TimerViewController.setActiveScreenshotSampleController(
                timerViewController,
                navigationController: navigationController
            )
            return navigationController
        }
    }

    static func installFloatingTimerButton(
        on navigationController: UINavigationController
    ) -> FloatingTimerButtonController {
        FloatingTimerButtonController.install(on: navigationController, modelContext: nil)
    }

    private static func makeActivityTypesViewController(
        sampleData: ScreenshotSampleData
    ) -> ActivityTypesViewController {
        let viewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        viewController.configureForScreenshotSample(
            activityTypes: sampleData.activityTypes,
            selectedTagIDs: []
        )
        return viewController
    }

    private static func makeFilteredActivityTypesViewController(
        sampleData: ScreenshotSampleData
    ) -> ActivityTypesViewController {
        let viewController = ActivityTypesViewController(
            nibName: "ActivityTypesViewController",
            bundle: nil
        )
        viewController.configureForScreenshotSample(
            activityTypes: sampleData.activityTypes,
            selectedTagIDs: sampleData.selectedTagIDs
        )
        return viewController
    }

    private static func makeActivityHistoryViewController(
        sampleData: ScreenshotSampleData
    ) -> ActivityHistoryViewController {
        let viewController = ActivityHistoryViewController(
            nibName: "ActivityHistoryViewController",
            bundle: nil
        )
        viewController.configureForScreenshotSample(
            activityType: sampleData.primaryActivityType
        )
        return viewController
    }

    private static func makeActivityDetailsViewController(
        sampleData: ScreenshotSampleData
    ) -> ActivityDetailsViewController {
        let viewController = ActivityDetailsViewController(
            nibName: "ActivityDetailsViewController",
            bundle: nil
        )
        viewController.configureForScreenshotSample(
            activity: sampleData.detailActivity,
            availableActivityTypes: sampleData.activityTypes,
            startsInEditMode: true
        )
        return viewController
    }

    private static func makeTimerViewController(
        sampleData: ScreenshotSampleData
    ) -> TimerViewController {
        let viewController = TimerViewController(
            nibName: "TimerViewController",
            bundle: nil
        )
        viewController.configureForScreenshotSample(
            activityTypes: sampleData.activityTypes,
            timers: sampleData.timers
        )
        return viewController
    }
}
#endif
