import Foundation
import SwiftData

@Model
final class ActivityType {
    @Attribute(.unique) var uniqueID: UUID
    var name: String
    var creationDate: Date
    var isFavorite: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Activity.activityType) var activities: [Activity]
    var tags: [ActivityTag]?

    init(
        uniqueID: UUID = UUID(),
        name: String,
        creationDate: Date = .now,
        isFavorite: Bool = false,
        activities: [Activity] = [],
        tags: [ActivityTag]? = nil
    ) {
        self.uniqueID = uniqueID
        self.name = name
        self.creationDate = creationDate
        self.isFavorite = isFavorite
        self.activities = activities
        self.tags = tags
    }
}
