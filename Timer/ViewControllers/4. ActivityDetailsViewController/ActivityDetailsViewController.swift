import UIKit
import SwiftData

final class ActivityDetailsViewController: UIViewController {
    var modelContext: ModelContext?
    var activity: Activity?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
    }

    private func configureAppearance() {
        title = "Activity Details"
        view.backgroundColor = .systemBackground
    }
}

extension ActivityDetailsViewController: FloatingTimerButtonContextProviding {
    var floatingTimerButtonContext: FloatingTimerButtonContext? {
        guard let activityType = activity?.activityType else {
            return nil
        }

        return .activityType(activityType)
    }
}
