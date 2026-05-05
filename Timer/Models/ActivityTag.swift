import Foundation
import SwiftData

@Model
final class ActivityTag {
    @Attribute(.unique) var uniqueID: UUID
    var name: String
    @Relationship(deleteRule: .nullify, inverse: \ActivityType.tags) var activityTypes: [ActivityType]

    init(
        uniqueID: UUID = UUID(),
        name: String,
        activityTypes: [ActivityType] = []
    ) {
        self.uniqueID = uniqueID
        self.name = name
        self.activityTypes = activityTypes
    }
}
