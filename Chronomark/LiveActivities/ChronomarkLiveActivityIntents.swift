import ActivityKit
import AppIntents
import Foundation
import SwiftData

struct ChronomarkLiveActivityPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"

    @Parameter(title: "Activity Type ID") var activityTypeID: String
    @Parameter(title: "Activity Name") var activityName: String
    @Parameter(title: "Elapsed Seconds") var elapsedSeconds: Int
    @Parameter(title: "Timer Start Timestamp") var timerStartTimestamp: Double
    @Parameter(title: "Font") var fontRawValue: String
    @Parameter(title: "Accent Color") var accentColorRawValue: String

    init() {
        activityTypeID = ""
        activityName = ""
        elapsedSeconds = 0
        timerStartTimestamp = 0
        fontRawValue = "manrope"
        accentColorRawValue = "teal"
    }

    init(
        activityTypeID: UUID,
        activityName: String,
        elapsedSeconds: Int,
        timerStartDate: Date?,
        fontRawValue: String,
        accentColorRawValue: String
    ) {
        self.activityTypeID = activityTypeID.uuidString
        self.activityName = activityName
        self.elapsedSeconds = elapsedSeconds
        timerStartTimestamp = timerStartDate?.timeIntervalSince1970 ?? 0
        self.fontRawValue = fontRawValue
        self.accentColorRawValue = accentColorRawValue
    }

    func perform() async throws -> some IntentResult {
        guard let activityTypeID = UUID(uuidString: activityTypeID) else {
            return .result()
        }

        try await ChronomarkLiveActivityIntentHandler.pause(
            activityTypeID: activityTypeID,
            activityName: activityName,
            fallbackElapsedSeconds: elapsedSeconds,
            timerStartTimestamp: timerStartTimestamp,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
        return .result()
    }
}

struct ChronomarkLiveActivityResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"

    @Parameter(title: "Activity Type ID") var activityTypeID: String
    @Parameter(title: "Activity Name") var activityName: String
    @Parameter(title: "Elapsed Seconds") var elapsedSeconds: Int
    @Parameter(title: "Font") var fontRawValue: String
    @Parameter(title: "Accent Color") var accentColorRawValue: String

    init() {
        activityTypeID = ""
        activityName = ""
        elapsedSeconds = 0
        fontRawValue = "manrope"
        accentColorRawValue = "teal"
    }

    init(
        activityTypeID: UUID,
        activityName: String,
        elapsedSeconds: Int,
        fontRawValue: String,
        accentColorRawValue: String
    ) {
        self.activityTypeID = activityTypeID.uuidString
        self.activityName = activityName
        self.elapsedSeconds = elapsedSeconds
        self.fontRawValue = fontRawValue
        self.accentColorRawValue = accentColorRawValue
    }

    func perform() async throws -> some IntentResult {
        guard let activityTypeID = UUID(uuidString: activityTypeID) else {
            return .result()
        }

        try await ChronomarkLiveActivityIntentHandler.resume(
            activityTypeID: activityTypeID,
            activityName: activityName,
            fallbackElapsedSeconds: elapsedSeconds,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
        return .result()
    }
}

struct ChronomarkLiveActivityStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"

    @Parameter(title: "Activity Type ID") var activityTypeID: String
    @Parameter(title: "Activity Name") var activityName: String
    @Parameter(title: "Elapsed Seconds") var elapsedSeconds: Int
    @Parameter(title: "Timer Start Timestamp") var timerStartTimestamp: Double
    @Parameter(title: "Font") var fontRawValue: String
    @Parameter(title: "Accent Color") var accentColorRawValue: String

    init() {
        activityTypeID = ""
        activityName = ""
        elapsedSeconds = 0
        timerStartTimestamp = 0
        fontRawValue = "manrope"
        accentColorRawValue = "teal"
    }

    init(
        activityTypeID: UUID,
        activityName: String,
        elapsedSeconds: Int,
        timerStartDate: Date?,
        fontRawValue: String,
        accentColorRawValue: String
    ) {
        self.activityTypeID = activityTypeID.uuidString
        self.activityName = activityName
        self.elapsedSeconds = elapsedSeconds
        timerStartTimestamp = timerStartDate?.timeIntervalSince1970 ?? 0
        self.fontRawValue = fontRawValue
        self.accentColorRawValue = accentColorRawValue
    }

    func perform() async throws -> some IntentResult {
        guard let activityTypeID = UUID(uuidString: activityTypeID) else {
            return .result()
        }

        try await ChronomarkLiveActivityIntentHandler.stop(
            activityTypeID: activityTypeID,
            activityName: activityName,
            fallbackElapsedSeconds: elapsedSeconds,
            timerStartTimestamp: timerStartTimestamp,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
        return .result()
    }
}

enum ChronomarkLiveActivityIntentHandler {
    static func pause(
        activityTypeID: UUID,
        activityName: String,
        fallbackElapsedSeconds: Int,
        timerStartTimestamp: Double,
        fontRawValue: String,
        accentColorRawValue: String
    ) async throws {
        let now = Date()
        let fallbackElapsedTime = fallbackElapsedTime(
            fallbackElapsedSeconds: fallbackElapsedSeconds,
            timerStartTimestamp: timerStartTimestamp,
            now: now
        )

        await updateLiveActivity(
            activityTypeID: activityTypeID,
            activityName: activityName,
            elapsedSeconds: Int(fallbackElapsedTime),
            status: "Paused",
            timerStartDate: nil,
            relevanceScore: 50,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )

        let elapsedTime: TimeInterval

        do {
            let context = try sharedModelContext()
            let cache = try timerCache(activityTypeID: activityTypeID, context: context)

            if let cache {
                elapsedTime = computedElapsedTime(for: cache, fallbackElapsedSeconds: fallbackElapsedSeconds, now: now)
                cache.timeElapsed = elapsedTime
                cache.isRunning = false
                cache.lastUpdateTime = now
                try context.save()
            } else {
                elapsedTime = fallbackElapsedTime
            }
        } catch {
            print("Failed to persist Live Activity pause: \(error)")
            return
        }

        await updateLiveActivity(
            activityTypeID: activityTypeID,
            activityName: activityName,
            elapsedSeconds: Int(elapsedTime),
            status: "Paused",
            timerStartDate: nil,
            relevanceScore: 50,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
    }

    static func resume(
        activityTypeID: UUID,
        activityName: String,
        fallbackElapsedSeconds: Int,
        fontRawValue: String,
        accentColorRawValue: String
    ) async throws {
        let now = Date()
        let context = try sharedModelContext()
        let cache = try timerCache(activityTypeID: activityTypeID, context: context)
        let elapsedTime: TimeInterval

        if let cache {
            elapsedTime = max(0, cache.timeElapsed)
            cache.isRunning = true
            cache.lastUpdateTime = now
            try context.save()
        } else {
            elapsedTime = max(0, TimeInterval(fallbackElapsedSeconds))
        }

        await updateLiveActivity(
            activityTypeID: activityTypeID,
            activityName: activityName,
            elapsedSeconds: Int(elapsedTime),
            status: "Running",
            timerStartDate: now.addingTimeInterval(-elapsedTime),
            relevanceScore: 100,
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
    }

    static func stop(
        activityTypeID: UUID,
        activityName: String,
        fallbackElapsedSeconds: Int,
        timerStartTimestamp: Double,
        fontRawValue: String,
        accentColorRawValue: String
    ) async throws {
        let now = Date()
        let context = try sharedModelContext()
        let cache = try timerCache(activityTypeID: activityTypeID, context: context)
        let elapsedTime: TimeInterval

        if let cache {
            elapsedTime = computedElapsedTime(for: cache, fallbackElapsedSeconds: fallbackElapsedSeconds, now: now)

            if let activityType = try activityType(activityTypeID: activityTypeID, context: context) {
                let completedActivity = Activity(
                    activityType: activityType,
                    activityStartTime: cache.startTime,
                    activityCompletionTime: now,
                    timeTaken: elapsedTime
                )
                activityType.activities.append(completedActivity)
                context.insert(completedActivity)
            }

            context.delete(cache)
            try context.save()
        } else {
            elapsedTime = fallbackElapsedTime(
                fallbackElapsedSeconds: fallbackElapsedSeconds,
                timerStartTimestamp: timerStartTimestamp,
                now: now
            )
        }

        await endLiveActivity(
            activityTypeID: activityTypeID,
            activityName: activityName,
            elapsedSeconds: Int(elapsedTime),
            fontRawValue: fontRawValue,
            accentColorRawValue: accentColorRawValue
        )
    }

    private static func sharedModelContext() throws -> ModelContext {
        try ModelContext(ChronomarkModelContainerFactory.makeSharedModelContainer())
    }

    private static func timerCache(
        activityTypeID: UUID,
        context: ModelContext
    ) throws -> ActivityTimerCache? {
        try context.fetch(FetchDescriptor<ActivityTimerCache>())
            .first { $0.activityTypeUniqueID == activityTypeID }
    }

    private static func activityType(
        activityTypeID: UUID,
        context: ModelContext
    ) throws -> ActivityType? {
        try context.fetch(FetchDescriptor<ActivityType>())
            .first { $0.uniqueID == activityTypeID }
    }

    private static func computedElapsedTime(
        for cache: ActivityTimerCache,
        fallbackElapsedSeconds: Int,
        now: Date
    ) -> TimeInterval {
        guard cache.isRunning else {
            return max(0, cache.timeElapsed)
        }

        return max(
            TimeInterval(fallbackElapsedSeconds),
            cache.timeElapsed + now.timeIntervalSince(cache.lastUpdateTime)
        )
    }

    private static func fallbackElapsedTime(
        fallbackElapsedSeconds: Int,
        timerStartTimestamp: Double,
        now: Date
    ) -> TimeInterval {
        guard timerStartTimestamp > 0 else {
            return max(0, TimeInterval(fallbackElapsedSeconds))
        }

        return max(
            TimeInterval(fallbackElapsedSeconds),
            now.timeIntervalSince(Date(timeIntervalSince1970: timerStartTimestamp))
        )
    }

    private static func updateLiveActivity(
        activityTypeID: UUID,
        activityName: String,
        elapsedSeconds: Int,
        status: String,
        timerStartDate: Date?,
        relevanceScore: Double,
        fontRawValue: String,
        accentColorRawValue: String
    ) async {
        let content = ActivityContent(
            state: ChronomarkTimerAttributes.ContentState(
                activityName: activityName,
                elapsedSeconds: max(0, elapsedSeconds),
                status: status,
                timerStartDate: timerStartDate,
                fontRawValue: fontRawValue,
                accentColorRawValue: accentColorRawValue
            ),
            staleDate: nil,
            relevanceScore: relevanceScore
        )

        let activities = ActivityKit.Activity<ChronomarkTimerAttributes>.activities
            .filter { $0.attributes.activityTypeUniqueID == activityTypeID }
        print("Live Activity update requested for \(activityTypeID). Matches: \(activities.count)")

        for activity in activities {
            await activity.update(content)
        }
    }

    private static func endLiveActivity(
        activityTypeID: UUID,
        activityName: String,
        elapsedSeconds: Int,
        fontRawValue: String,
        accentColorRawValue: String
    ) async {
        let content = ActivityContent(
            state: ChronomarkTimerAttributes.ContentState(
                activityName: activityName,
                elapsedSeconds: max(0, elapsedSeconds),
                status: "Stopped",
                timerStartDate: nil,
                fontRawValue: fontRawValue,
                accentColorRawValue: accentColorRawValue
            ),
            staleDate: nil,
            relevanceScore: 0
        )

        let activities = ActivityKit.Activity<ChronomarkTimerAttributes>.activities
            .filter { $0.attributes.activityTypeUniqueID == activityTypeID }
        print("Live Activity end requested for \(activityTypeID). Matches: \(activities.count)")

        for activity in activities {
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }
}
