import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var uniqueID: UUID
    var activityType: ActivityType
    var activityStartTime: Date?
    var activityCompletionTime: Date?
    var timeTaken: TimeInterval?

    init(
        uniqueID: UUID = UUID(),
        activityType: ActivityType,
        activityStartTime: Date? = nil,
        activityCompletionTime: Date? = nil,
        timeTaken: TimeInterval? = nil
    ) {
        self.uniqueID = uniqueID
        self.activityType = activityType
        self.activityStartTime = activityStartTime
        self.activityCompletionTime = activityCompletionTime
        self.timeTaken = timeTaken
    }
}
