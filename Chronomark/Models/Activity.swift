import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var uniqueID: UUID
    var activityType: ActivityType
    var activityStartTime: Date?
    var activityCompletionTime: Date?
    var timeTaken: TimeInterval?
    var activityNotes: String?
    var isMutedFromSummary: Bool?

    init(
        uniqueID: UUID = UUID(),
        activityType: ActivityType,
        activityStartTime: Date? = nil,
        activityCompletionTime: Date? = nil,
        timeTaken: TimeInterval? = nil,
        activityNotes: String? = nil,
        isMutedFromSummary: Bool? = false
    ) {
        self.uniqueID = uniqueID
        self.activityType = activityType
        self.activityStartTime = activityStartTime
        self.activityCompletionTime = activityCompletionTime
        self.timeTaken = timeTaken
        self.activityNotes = activityNotes
        self.isMutedFromSummary = isMutedFromSummary
    }
}
