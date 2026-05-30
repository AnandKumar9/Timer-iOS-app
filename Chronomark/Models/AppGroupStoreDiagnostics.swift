import SwiftData
import UIKit

enum AppGroupStoreDiagnostics {
    private static let migrationCompletedVersionKey = "AppGroupSwiftDataMigration.completedVersion"
    private static let appGroupMigrationUserDefaultsKeys = [
        "AppGroupSwiftDataMigration.legacyStoreExistedAtMigration",
        "AppGroupSwiftDataMigration.legacyCountsAtMigration",
        "AppGroupSwiftDataMigration.sharedCountsAfterMigration",
        "AppGroupSwiftDataMigration.migratedAt"
    ]
    private static let appGroupStoreFileNames = [
        "Chronomark.store",
        "Chronomark.store-shm",
        "Chronomark.store-wal"
    ]
    private static let legacyStoreFileNames = [
        "default.store",
        "default.store-shm",
        "default.store-wal"
    ]

    @MainActor
    static func makeReport(modelContext: ModelContext?) -> String {
        var lines: [String] = []

        appendAppDetails(to: &lines)
        lines.append("")
        appendMainTargetUserDefaults(to: &lines)
        lines.append("")
        appendAppGroupStoreDetails(to: &lines)
        lines.append("")
        appendLegacyStoreDetails(to: &lines)
        lines.append("")
        appendCurrentStoreCounts(modelContext: modelContext, to: &lines)
        lines.append("")
        appendSharedStoreCounts(to: &lines)

        return lines.joined(separator: "\n")
    }

    @MainActor
    static func presentReportIfNeeded(
        from presentingViewController: UIViewController,
        modelContext: ModelContext?
    ) {
        let report = makeReport(modelContext: modelContext)

        let alertController = UIAlertController(
            title: "Store Diagnostics",
            message: report,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: "Copy", style: .default) { _ in
                UIPasteboard.general.string = report
            }
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            topPresentedViewController(from: presentingViewController)
                .present(alertController, animated: true)
        }
    }

    private static func appendAppDetails(to lines: inout [String]) {
        let bundle = Bundle.main

        lines.append("")
        lines.append("Bundle ID: \(bundle.bundleIdentifier ?? "unknown")")
        lines.append("Version: \(bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
        lines.append("Build: \(bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        lines.append("App Group ID: \(ChronomarkModelContainerFactory.appGroupIdentifier)")
    }

    @MainActor
    private static func appendAppGroupStoreDetails(to lines: inout [String]) {
        lines.append("App Group Store Details -")

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: ChronomarkModelContainerFactory.appGroupIdentifier
        ) {
            lines.append("URL: \(containerURL.path)")
            appendFiles(
                named: appGroupStoreFileNames,
                in: containerURL,
                to: &lines
            )
        } else {
            lines.append("URL: unavailable")
        }

        lines.append("Record Counts -")
        appendSharedStoreRecordCounts(to: &lines)
    }

    private static func appendMainTargetUserDefaults(to lines: inout [String]) {
        lines.append("Main Target Migration UserDefaults -")

        guard let appGroupUserDefaults = UserDefaults(
            suiteName: ChronomarkModelContainerFactory.appGroupIdentifier
        ) else {
            lines.append("migrationStepCrossed: unavailable")
            return
        }

        lines.append("migrationStepCrossed: \(appGroupUserDefaults.integer(forKey: migrationCompletedVersionKey))")
        for key in appGroupMigrationUserDefaultsKeys {
            let value = appGroupUserDefaults.object(forKey: key)
            lines.append(
                "\(displayName(forAppGroupMigrationKey: key)): \(formattedMigrationValue(value, forKey: key))"
            )
        }
    }

    @MainActor
    private static func appendLegacyStoreDetails(to lines: inout [String]) {
        lines.append("Legacy Store Details -")

        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            lines.append("Application Support URL: unavailable")
            return
        }

        lines.append("URL: \(applicationSupportURL.path)")
        appendFiles(
            named: legacyStoreFileNames,
            in: applicationSupportURL,
            to: &lines
        )
        lines.append("Record Counts -")

        guard legacyStoreExists() else {
            lines.append("Skipped: default.store is not present")
            return
        }

        do {
            let container = try ChronomarkModelContainerFactory.makeLegacyModelContainer()
            appendCounts(modelContext: container.mainContext, to: &lines)
        } catch {
            lines.append("Open failed: \(error)")
        }
    }

    @MainActor
    private static func appendCurrentStoreCounts(
        modelContext: ModelContext?,
        to lines: inout [String]
    ) { 
        lines.append("Current UI Model Context Counts -")

        guard let modelContext else {
            lines.append("Unavailable")
            return
        }

        appendCounts(modelContext: modelContext, to: &lines)
    }

    @MainActor
    private static func appendSharedStoreCounts(to lines: inout [String]) {
        lines.append("Fresh Shared Store Counts -")
        appendSharedStoreRecordCounts(to: &lines)
    }

    @MainActor
    private static func appendSharedStoreRecordCounts(to lines: inout [String]) {
        do {
            let container = try ChronomarkModelContainerFactory.makeSharedModelContainer()
            let context = ModelContext(container)
            appendCounts(modelContext: context, to: &lines)
        } catch {
            lines.append("Open failed: \(error)")
        }
    }

    private static func appendFiles(
        named fileNames: [String],
        in directoryURL: URL,
        to lines: inout [String]
    ) {
        for fileName in fileNames {
            let fileURL = directoryURL.appendingPathComponent(fileName)
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            let size = fileSize(fileURL: fileURL)
            lines.append("\(fileName): exists=\(exists) size=\(size)")
        }
    }

    @MainActor
    private static func appendCounts(
        modelContext: ModelContext,
        to lines: inout [String]
    ) {
        do {
            lines.append("ActivityType: \(try modelContext.fetchCount(FetchDescriptor<ActivityType>()))")
            lines.append("Activity: \(try modelContext.fetchCount(FetchDescriptor<Activity>()))")
            lines.append("ActivityTag: \(try modelContext.fetchCount(FetchDescriptor<ActivityTag>()))")
            lines.append("ActivityTimerCache: \(try modelContext.fetchCount(FetchDescriptor<ActivityTimerCache>()))")
        } catch {
            lines.append("Count failed: \(error)")
        }
    }

    private static func fileSize(fileURL: URL) -> UInt64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return 0
        }

        return fileSize.uint64Value
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

    private static func formattedUserDefaultsValue(_ value: Any?) -> String {
        guard let value else {
            return "unset"
        }

        if let string = value as? String {
            return "\"\(string)\""
        }

        if let array = value as? [String] {
            return "[\(array.map { "\"\($0)\"" }.joined(separator: ", "))]"
        }

        if let dictionary = value as? [String: Int] {
            return dictionary
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
        }

        return String(describing: value)
    }

    private static func formattedMigrationValue(_ value: Any?, forKey key: String) -> String {
        guard
            key == "AppGroupSwiftDataMigration.legacyCountsAtMigration"
                || key == "AppGroupSwiftDataMigration.sharedCountsAfterMigration"
        else {
            return formattedUserDefaultsValue(value)
        }

        guard let dictionary = value as? [String: Int] else {
            return formattedUserDefaultsValue(value)
        }

        return "\(dictionary["Activity"] ?? 0)"
    }

    private static func displayName(forAppGroupMigrationKey key: String) -> String {
        key.replacingOccurrences(
            of: "AppGroupSwiftDataMigration.",
            with: ""
        )
    }

    private static func topPresentedViewController(from viewController: UIViewController) -> UIViewController {
        var topViewController = viewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}
