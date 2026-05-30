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
        relevanceScore: Double,
        showControls: Bool
    ) throws -> ActivityKit.Activity<ChronomarkTimerAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return nil
        }

        return try ActivityKit.Activity<ChronomarkTimerAttributes>.request(
            attributes: ChronomarkTimerAttributes(
                activityTypeUniqueID: activityTypeID,
                activityName: name,
                showControls: showControls
            ),
            content: ActivityContent(
                state: ChronomarkTimerAttributes.ContentState(
                    activityName: name,
                    elapsedSeconds: elapsedSeconds,
                    status: status,
                    timerStartDate: timerStartDate,
                    fontRawValue: AppTheme.selectedFont.rawValue,
                    accentColorRawValue: AppTheme.selectedAccentColor.rawValue
                ),
                staleDate: nil,
                relevanceScore: relevanceScore
            ),
            pushType: nil
        )
    }

    static func updateActivity(
        activityTypeID: UUID,
        name: String? = nil,
        elapsedSeconds: Int,
        status: String,
        timerStartDate: Date?,
        relevanceScore: Double = 100
    ) {
        for activity in activities(activityTypeID: activityTypeID) {
            let content = ActivityContent(
                state: ChronomarkTimerAttributes.ContentState(
                    activityName: name ?? activity.attributes.activityName,
                    elapsedSeconds: elapsedSeconds,
                    status: status,
                    timerStartDate: timerStartDate,
                    fontRawValue: AppTheme.selectedFont.rawValue,
                    accentColorRawValue: AppTheme.selectedAccentColor.rawValue
                ),
                staleDate: nil,
                relevanceScore: relevanceScore
            )
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
        relevanceScore: Double,
        showControls: Bool,
        canStartNewActivity: Bool = true
    ) throws -> ActivityKit.Activity<ChronomarkTimerAttributes>? {
        let matchingActivities = activities(activityTypeID: activityTypeID)
        guard matchingActivities.isEmpty else {
            updateActivity(
                activityTypeID: activityTypeID,
                name: name,
                elapsedSeconds: elapsedSeconds,
                status: status,
                timerStartDate: timerStartDate,
                relevanceScore: relevanceScore
            )
            return matchingActivities.first
        }

        guard canStartNewActivity else {
            return nil
        }

        return try startActivity(
            activityTypeID: activityTypeID,
            name: name,
            elapsedSeconds: elapsedSeconds,
            status: status,
            timerStartDate: timerStartDate,
            relevanceScore: relevanceScore,
            showControls: showControls
        )
    }

    static func endActivity(
        activityTypeID: UUID,
        elapsedSeconds: Int,
        status: String = "Paused"
    ) {
        for activity in activities(activityTypeID: activityTypeID) {
            let content = ActivityContent(
                state: ChronomarkTimerAttributes.ContentState(
                    activityName: activity.attributes.activityName,
                    elapsedSeconds: elapsedSeconds,
                    status: status,
                    timerStartDate: nil,
                    fontRawValue: AppTheme.selectedFont.rawValue,
                    accentColorRawValue: AppTheme.selectedAccentColor.rawValue
                ),
                staleDate: nil,
                relevanceScore: 0
            )
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
