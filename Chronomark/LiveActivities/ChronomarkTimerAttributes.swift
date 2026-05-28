import ActivityKit
import Foundation

struct ChronomarkTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var activityName: String
        var elapsedSeconds: Int
        var status: String
        var timerStartDate: Date?
        var fontRawValue: String
        var accentColorRawValue: String
    }

    var activityTypeUniqueID: UUID
    var activityName: String
}
