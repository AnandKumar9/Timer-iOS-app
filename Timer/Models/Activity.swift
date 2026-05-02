import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var activityTypeID: UUID
    var activityType: ActivityType?
    var actvityStartTime: Date
    var activityCompletionTime: Date?

    init(
        activityTypeID: UUID = UUID(),
        activityType: ActivityType? = nil,
        actvityStartTime: Date = .now,
        activityCompletionTime: Date? = nil
    ) {
        self.activityTypeID = activityTypeID
        self.activityType = activityType
        self.actvityStartTime = actvityStartTime
        self.activityCompletionTime = activityCompletionTime
    }
}
