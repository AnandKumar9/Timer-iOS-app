import Foundation
import SwiftData

enum ChronomarkModelContainerFactory {
    static let appGroupIdentifier = "group.com.outonaweekend.chronomark"

    private static let sharedStoreFileName = "Chronomark.store"

    static var schema: Schema {
        Schema([
            ActivityType.self,
            Activity.self,
            ActivityTag.self,
            ActivityTimerCache.self
        ])
    }

    @MainActor
    static func makeAppModelContainer() throws -> ModelContainer {
        try AppGroupSwiftDataMigration.migrateIfNeeded()
        return try makeSharedModelContainer()
    }

    static func makeSharedModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            url: try sharedStoreURL()
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeLegacyModelContainer() throws -> ModelContainer {
        try ModelContainer(for: schema)
    }

    static func sharedUserDefaults() throws -> UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw AppGroupSwiftDataMigration.MigrationError.appGroupUnavailable
        }

        return userDefaults
    }

    private static func sharedStoreURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw AppGroupSwiftDataMigration.MigrationError.appGroupUnavailable
        }

        return containerURL.appendingPathComponent(sharedStoreFileName)
    }
}

enum AppGroupSwiftDataMigration {
    enum MigrationError: Error {
        case appGroupUnavailable
    }

    private static let migrationVersion = 1
    private static let completedVersionKey = "AppGroupSwiftDataMigration.completedVersion"
    private static let legacyStoreExistedAtMigrationKey = "AppGroupSwiftDataMigration.legacyStoreExistedAtMigration"
    private static let legacyCountsAtMigrationKey = "AppGroupSwiftDataMigration.legacyCountsAtMigration"
    private static let sharedCountsAfterMigrationKey = "AppGroupSwiftDataMigration.sharedCountsAfterMigration"
    private static let migratedAtKey = "AppGroupSwiftDataMigration.migratedAt"

    @MainActor
    static func migrateIfNeeded() throws {
        let userDefaults = try ChronomarkModelContainerFactory.sharedUserDefaults()
        guard userDefaults.integer(forKey: completedVersionKey) < migrationVersion else {
            deleteLegacyStoreFilesIfPresent()
            return
        }

        let legacyStoreExistedAtMigration = legacyStoreExists()
        let legacyContainer = try ChronomarkModelContainerFactory.makeLegacyModelContainer()
        let sharedContainer = try ChronomarkModelContainerFactory.makeSharedModelContainer()
        let legacyCountsAtMigration = try recordCounts(in: legacyContainer.mainContext)

        try migrate(
            from: legacyContainer.mainContext,
            to: sharedContainer.mainContext
        )

        let sharedCountsAfterMigration = try recordCounts(in: sharedContainer.mainContext)
        userDefaults.set(legacyStoreExistedAtMigration, forKey: legacyStoreExistedAtMigrationKey)
        userDefaults.set(legacyCountsAtMigration, forKey: legacyCountsAtMigrationKey)
        userDefaults.set(sharedCountsAfterMigration, forKey: sharedCountsAfterMigrationKey)
        userDefaults.set(Date(), forKey: migratedAtKey)
        userDefaults.set(migrationVersion, forKey: completedVersionKey)
        deleteLegacyStoreFilesIfPresent()
    }

    private static func migrate(from legacyContext: ModelContext, to sharedContext: ModelContext) throws {
        let legacyTags = try legacyContext.fetch(FetchDescriptor<ActivityTag>())
        let legacyActivityTypes = try legacyContext.fetch(FetchDescriptor<ActivityType>())
        let legacyActivities = try legacyContext.fetch(FetchDescriptor<Activity>())
        let legacyCaches = try legacyContext.fetch(FetchDescriptor<ActivityTimerCache>())

        let sharedTags = try sharedContext.fetch(FetchDescriptor<ActivityTag>())
        let sharedActivityTypes = try sharedContext.fetch(FetchDescriptor<ActivityType>())
        let sharedActivities = try sharedContext.fetch(FetchDescriptor<Activity>())
        let sharedCaches = try sharedContext.fetch(FetchDescriptor<ActivityTimerCache>())

        var tagMap = Dictionary(uniqueKeysWithValues: sharedTags.map { ($0.uniqueID, $0) })
        var activityTypeMap = Dictionary(uniqueKeysWithValues: sharedActivityTypes.map { ($0.uniqueID, $0) })
        var activityMap = Dictionary(uniqueKeysWithValues: sharedActivities.map { ($0.uniqueID, $0) })
        var cacheMap = Dictionary(uniqueKeysWithValues: sharedCaches.map { ($0.activityTypeUniqueID, $0) })

        for legacyTag in legacyTags {
            if let sharedTag = tagMap[legacyTag.uniqueID] {
                sharedTag.name = legacyTag.name
            } else {
                let sharedTag = ActivityTag(
                    uniqueID: legacyTag.uniqueID,
                    name: legacyTag.name
                )
                sharedContext.insert(sharedTag)
                tagMap[sharedTag.uniqueID] = sharedTag
            }
        }

        for legacyActivityType in legacyActivityTypes {
            let mappedTags = legacyActivityType.tags?.compactMap { tagMap[$0.uniqueID] }

            if let sharedActivityType = activityTypeMap[legacyActivityType.uniqueID] {
                sharedActivityType.name = legacyActivityType.name
                sharedActivityType.creationDate = legacyActivityType.creationDate
                sharedActivityType.isFavorite = legacyActivityType.isFavorite
                sharedActivityType.isLiveActivitiesOn = legacyActivityType.isLiveActivitiesOn
                sharedActivityType.showControlsInLiveActivities = legacyActivityType.showControlsInLiveActivities
                sharedActivityType.tags = mappedTags
            } else {
                let sharedActivityType = ActivityType(
                    uniqueID: legacyActivityType.uniqueID,
                    name: legacyActivityType.name,
                    creationDate: legacyActivityType.creationDate,
                    isFavorite: legacyActivityType.isFavorite,
                    isLiveActivitiesOn: legacyActivityType.isLiveActivitiesOn,
                    showControlsInLiveActivities: legacyActivityType.showControlsInLiveActivities,
                    tags: mappedTags
                )
                sharedContext.insert(sharedActivityType)
                activityTypeMap[sharedActivityType.uniqueID] = sharedActivityType
            }
        }

        for legacyActivity in legacyActivities {
            guard let sharedActivityType = activityTypeMap[legacyActivity.activityType.uniqueID] else {
                continue
            }

            if let sharedActivity = activityMap[legacyActivity.uniqueID] {
                sharedActivity.activityType = sharedActivityType
                sharedActivity.activityStartTime = legacyActivity.activityStartTime
                sharedActivity.activityCompletionTime = legacyActivity.activityCompletionTime
                sharedActivity.timeTaken = legacyActivity.timeTaken
                sharedActivity.activityNotes = legacyActivity.activityNotes
                sharedActivity.isMutedFromSummary = legacyActivity.isMutedFromSummary
            } else {
                let sharedActivity = Activity(
                    uniqueID: legacyActivity.uniqueID,
                    activityType: sharedActivityType,
                    activityStartTime: legacyActivity.activityStartTime,
                    activityCompletionTime: legacyActivity.activityCompletionTime,
                    timeTaken: legacyActivity.timeTaken,
                    activityNotes: legacyActivity.activityNotes,
                    isMutedFromSummary: legacyActivity.isMutedFromSummary
                )
                sharedContext.insert(sharedActivity)
                activityMap[sharedActivity.uniqueID] = sharedActivity
            }
        }

        for legacyCache in legacyCaches {
            if let sharedCache = cacheMap[legacyCache.activityTypeUniqueID] {
                sharedCache.startTime = legacyCache.startTime
                sharedCache.timeElapsed = legacyCache.timeElapsed
                sharedCache.isRunning = legacyCache.isRunning
                sharedCache.lastUpdateTime = legacyCache.lastUpdateTime
            } else {
                let sharedCache = ActivityTimerCache(
                    activityTypeUniqueID: legacyCache.activityTypeUniqueID,
                    startTime: legacyCache.startTime,
                    timeElapsed: legacyCache.timeElapsed,
                    isRunning: legacyCache.isRunning,
                    lastUpdateTime: legacyCache.lastUpdateTime
                )
                sharedContext.insert(sharedCache)
                cacheMap[sharedCache.activityTypeUniqueID] = sharedCache
            }
        }

        try sharedContext.save()
    }

    @MainActor
    private static func recordCounts(in modelContext: ModelContext) throws -> [String: Int] {
        [
            "ActivityType": try modelContext.fetchCount(FetchDescriptor<ActivityType>()),
            "Activity": try modelContext.fetchCount(FetchDescriptor<Activity>()),
            "ActivityTag": try modelContext.fetchCount(FetchDescriptor<ActivityTag>()),
            "ActivityTimerCache": try modelContext.fetchCount(FetchDescriptor<ActivityTimerCache>())
        ]
    }

    private static func deleteLegacyStoreFilesIfPresent() {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        let legacyStoreFileNames = [
            "default.store",
            "default.store-shm",
            "default.store-wal"
        ]

        for fileName in legacyStoreFileNames {
            let fileURL = applicationSupportURL.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue
            }

            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                assertionFailure("Unable to delete legacy SwiftData store file \(fileURL): \(error)")
            }
        }
    }

    private static func legacyStoreExists() -> Bool {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return false
        }

        let storeURL = applicationSupportURL.appendingPathComponent("default.store")
        return FileManager.default.fileExists(atPath: storeURL.path)
    }
}
