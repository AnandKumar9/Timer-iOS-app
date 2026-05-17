import ActivityKit
import Foundation

struct ChronomarkTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var status: String
        var timerStartDate: Date?
    }

    var activityTypeUniqueID: UUID
    var activityName: String
}
