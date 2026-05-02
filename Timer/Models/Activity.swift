import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var activityTypeID: UUID
    var activityType: ActivityType
    var activityStartTime: Date?
    var activityCompletionTime: Date?

    init(
        activityTypeID: UUID = UUID(),
        activityType: ActivityType,
        activityStartTime: Date? = nil,
        activityCompletionTime: Date? = nil
    ) {
        self.activityTypeID = activityTypeID
        self.activityType = activityType
        self.activityStartTime = activityStartTime
        self.activityCompletionTime = activityCompletionTime
    }
}
