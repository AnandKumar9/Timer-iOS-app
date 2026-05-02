import Foundation
import SwiftData

@Model
final class ActivityType {
    @Attribute(.unique) var activityID: UUID
    var activityName: String
    @Relationship(deleteRule: .cascade, inverse: \Activity.activityType) var activities: [Activity]

    init(
        activityID: UUID = UUID(),
        activityName: String,
        activities: [Activity] = []
    ) {
        self.activityID = activityID
        self.activityName = activityName
        self.activities = activities
    }
}
