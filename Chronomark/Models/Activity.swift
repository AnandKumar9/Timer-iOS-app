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

enum ActivityCompletionPersistence {
    private static let matchingStartTimeTolerance: TimeInterval = 1

    @discardableResult
    static func upsertCompletedActivity(
        _ activity: Activity,
        in modelContext: ModelContext
    ) throws -> Activity? {
        guard
            let startTime = activity.activityStartTime,
            activity.activityCompletionTime != nil
        else {
            return nil
        }

        if let existingActivity = try existingCompletedActivity(
            activityTypeID: activity.activityType.uniqueID,
            startTime: startTime,
            in: modelContext
        ) {
            return existingActivity
        }

        if !activity.activityType.activities.contains(where: { $0 === activity }) {
            activity.activityType.activities.append(activity)
        }

        modelContext.insert(activity)
        return activity
    }

    private static func existingCompletedActivity(
        activityTypeID: UUID,
        startTime: Date,
        in modelContext: ModelContext
    ) throws -> Activity? {
        try modelContext.fetch(FetchDescriptor<Activity>())
            .first { activity in
                guard
                    activity.activityType.uniqueID == activityTypeID,
                    activity.activityCompletionTime != nil,
                    let existingStartTime = activity.activityStartTime
                else {
                    return false
                }

                return abs(existingStartTime.timeIntervalSince(startTime)) <= matchingStartTimeTolerance
            }
    }
}
