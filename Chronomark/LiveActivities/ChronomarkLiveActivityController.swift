import ActivityKit
import Foundation

enum ChronomarkLiveActivityController {
    @discardableResult
    static func startActivity(
        activityTypeID: UUID,
        name: String,
        elapsedSeconds: Int,
        status: String,
        timerStartDate: Date?,
        relevanceScore: Double
    ) throws -> ActivityKit.Activity<ChronomarkTimerAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return nil
        }

        return try ActivityKit.Activity<ChronomarkTimerAttributes>.request(
            attributes: ChronomarkTimerAttributes(
                activityTypeUniqueID: activityTypeID,
                activityName: name
            ),
            content: ActivityContent(
                state: ChronomarkTimerAttributes.ContentState(
                    elapsedSeconds: elapsedSeconds,
                    status: status,
                    timerStartDate: timerStartDate
                ),
                staleDate: nil,
                relevanceScore: relevanceScore
            ),
            pushType: nil
        )
    }

    static func updateActivity(
        activityTypeID: UUID,
        elapsedSeconds: Int,
        status: String,
        timerStartDate: Date?,
        relevanceScore: Double = 100
    ) {
        let content = ActivityContent(
            state: ChronomarkTimerAttributes.ContentState(
                elapsedSeconds: elapsedSeconds,
                status: status,
                timerStartDate: timerStartDate
            ),
            staleDate: nil,
            relevanceScore: relevanceScore
        )

        for activity in activities(activityTypeID: activityTypeID) {
            Task {
                await activity.update(content)
            }
        }
    }

    @discardableResult
    static func startOrUpdateActivity(
        activityTypeID: UUID,
        name: String,
        elapsedSeconds: Int,
        status: String,
        timerStartDate: Date?,
        relevanceScore: Double
    ) throws -> ActivityKit.Activity<ChronomarkTimerAttributes>? {
        let matchingActivities = activities(activityTypeID: activityTypeID)
        guard matchingActivities.isEmpty else {
            updateActivity(
                activityTypeID: activityTypeID,
                elapsedSeconds: elapsedSeconds,
                status: status,
                timerStartDate: timerStartDate,
                relevanceScore: relevanceScore
            )
            return matchingActivities.first
        }

        return try startActivity(
            activityTypeID: activityTypeID,
            name: name,
            elapsedSeconds: elapsedSeconds,
            status: status,
            timerStartDate: timerStartDate,
            relevanceScore: relevanceScore
        )
    }

    static func endActivity(
        activityTypeID: UUID,
        elapsedSeconds: Int,
        status: String = "Paused"
    ) {
        let content = ActivityContent(
            state: ChronomarkTimerAttributes.ContentState(
                elapsedSeconds: elapsedSeconds,
                status: status,
                timerStartDate: nil
            ),
            staleDate: nil,
            relevanceScore: 0
        )

        for activity in activities(activityTypeID: activityTypeID) {
            Task {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }

    private static func activities(
        activityTypeID: UUID
    ) -> [ActivityKit.Activity<ChronomarkTimerAttributes>] {
        ActivityKit.Activity<ChronomarkTimerAttributes>.activities.filter {
            $0.attributes.activityTypeUniqueID == activityTypeID
        }
    }
}
