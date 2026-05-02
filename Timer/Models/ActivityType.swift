import Foundation
import SwiftData

@Model
final class ActivityType {
    @Attribute(.unique) var uniqueID: UUID
    var name: String
    var creationDate: Date
    @Relationship(deleteRule: .cascade, inverse: \Activity.activityType) var activities: [Activity]

    init(
        uniqueID: UUID = UUID(),
        name: String,
        creationDate: Date = .now,
        activities: [Activity] = []
    ) {
        self.uniqueID = uniqueID
        self.name = name
        self.creationDate = creationDate
        self.activities = activities
    }
}
