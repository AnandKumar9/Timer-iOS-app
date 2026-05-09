import Foundation
import SwiftData

@Model
final class ActivityTimerCache {
    @Attribute(.unique) var activityTypeUniqueID: UUID
    var startTime: Date
    var timeElapsed: TimeInterval
    var isRunning: Bool
    var lastUpdateTime: Date

    init(
        activityTypeUniqueID: UUID,
        startTime: Date,
        timeElapsed: TimeInterval,
        isRunning: Bool,
        lastUpdateTime: Date
    ) {
        self.activityTypeUniqueID = activityTypeUniqueID
        self.startTime = startTime
        self.timeElapsed = timeElapsed
        self.isRunning = isRunning
        self.lastUpdateTime = lastUpdateTime
    }
}
