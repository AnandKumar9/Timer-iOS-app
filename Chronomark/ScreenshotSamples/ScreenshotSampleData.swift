#if DEBUG
import Foundation

enum ScreenshotSampleScreen: String {
    case activityTypes = "activity-types"
    case activityTypesFiltered = "activity-types-filtered"
    case activityHistory = "activity-history"
    case activityDetails = "activity-details"
    case timers
}

struct ScreenshotSampleTimer {
    let activityTypeID: UUID
    let state: RestoredTimerControlsState
}

struct ScreenshotSampleData {
    let activityTypes: [ActivityType]
    let timers: [ScreenshotSampleTimer]
    let selectedTagIDs: Set<UUID>

    var primaryActivityType: ActivityType? {
        activityTypes.first { $0.name == "Deep Work" } ?? activityTypes.first
    }

    var detailActivity: Activity? {
        primaryActivityType?.activities.first
    }
}

enum ScreenshotSampleDataLoader {
    private struct Fixture: Decodable {
        let tags: [TagFixture]
        let activityTypes: [ActivityTypeFixture]
        let timers: [TimerFixture]
        let selectedTagIDs: [UUID]
    }

    private struct TagFixture: Decodable {
        let id: UUID
        let name: String
    }

    private struct ActivityTypeFixture: Decodable {
        let id: UUID
        let name: String
        let createdDaysAgo: Int
        let tagIDs: [UUID]
        let activities: [ActivityFixture]
    }

    private struct ActivityFixture: Decodable {
        let id: UUID
        let startMinutesAgo: TimeInterval
        let durationSeconds: TimeInterval
    }

    private struct TimerFixture: Decodable {
        let activityTypeID: UUID
        let startMinutesAgo: TimeInterval
        let elapsedSeconds: TimeInterval
        let isRunning: Bool
        let lastUpdatedSecondsAgo: TimeInterval
    }

    static func load() -> ScreenshotSampleData {
        let fixture = loadFixture()
        let tagsByID = Dictionary(
            uniqueKeysWithValues: fixture.tags.map { fixtureTag in
                (
                    fixtureTag.id,
                    ActivityTag(uniqueID: fixtureTag.id, name: fixtureTag.name)
                )
            }
        )
        let now = Date()

        let activityTypes = fixture.activityTypes.map { fixtureActivityType in
            let activityType = ActivityType(
                uniqueID: fixtureActivityType.id,
                name: fixtureActivityType.name,
                creationDate: now.addingTimeInterval(TimeInterval(-fixtureActivityType.createdDaysAgo * 86_400)),
                tags: fixtureActivityType.tagIDs.compactMap { tagsByID[$0] }
            )

            activityType.activities = fixtureActivityType.activities.map { fixtureActivity in
                let startTime = now.addingTimeInterval(-fixtureActivity.startMinutesAgo * 60)
                let completionTime = startTime.addingTimeInterval(fixtureActivity.durationSeconds)
                return Activity(
                    uniqueID: fixtureActivity.id,
                    activityType: activityType,
                    activityStartTime: startTime,
                    activityCompletionTime: completionTime,
                    timeTaken: fixtureActivity.durationSeconds
                )
            }

            return activityType
        }

        let timers = fixture.timers.map { fixtureTimer in
            ScreenshotSampleTimer(
                activityTypeID: fixtureTimer.activityTypeID,
                state: RestoredTimerControlsState(
                    startTime: now.addingTimeInterval(-fixtureTimer.startMinutesAgo * 60),
                    timeElapsed: fixtureTimer.elapsedSeconds,
                    isRunning: fixtureTimer.isRunning,
                    lastUpdateTime: now.addingTimeInterval(-fixtureTimer.lastUpdatedSecondsAgo)
                )
            )
        }

        return ScreenshotSampleData(
            activityTypes: activityTypes,
            timers: timers,
            selectedTagIDs: Set(fixture.selectedTagIDs)
        )
    }

    private static func loadFixture() -> Fixture {
        guard let url = Bundle.main.url(
            forResource: "ScreenshotSampleData",
            withExtension: "json"
        ) else {
            preconditionFailure("ScreenshotSampleData.json is missing from the Debug app bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Fixture.self, from: data)
        } catch {
            preconditionFailure("Unable to decode ScreenshotSampleData.json: \(error)")
        }
    }
}
#endif
