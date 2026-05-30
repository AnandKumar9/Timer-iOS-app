import Foundation
import SwiftData

@Model
final class ActivityType {
    @Attribute(.unique) var uniqueID: UUID
    var name: String
    var creationDate: Date
    var isFavorite: Bool = false
    var isLiveActivitiesOn: Bool = true
    var showControlsInLiveActivities: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \Activity.activityType) var activities: [Activity]
    var tags: [ActivityTag]?

    init(
        uniqueID: UUID = UUID(),
        name: String,
        creationDate: Date = .now,
        isFavorite: Bool = false,
        isLiveActivitiesOn: Bool = true,
        showControlsInLiveActivities: Bool = true,
        activities: [Activity] = [],
        tags: [ActivityTag]? = nil
    ) {
        self.uniqueID = uniqueID
        self.name = name
        self.creationDate = creationDate
        self.isFavorite = isFavorite
        self.isLiveActivitiesOn = isLiveActivitiesOn
        self.showControlsInLiveActivities = showControlsInLiveActivities
        self.activities = activities
        self.tags = tags
    }
}
