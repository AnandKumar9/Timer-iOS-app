import SwiftData
import UIKit

enum AppGroupStoreDiagnostics {
    private static let migrationCompletedVersionKey = "AppGroupSwiftDataMigration.completedVersion"
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
        let bundle = Bundle.main

        lines.append("Chronomark Store Diagnostics")
        lines.append("Bundle ID: \(bundle.bundleIdentifier ?? "unknown")")
        lines.append("Version: \(bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
        lines.append("Build: \(bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")")
        lines.append("App Group ID: \(ChronomarkModelContainerFactory.appGroupIdentifier)")
        lines.append("")

        appendAppGroupDetails(to: &lines)
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
        print(report)

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

    private static func appendAppGroupDetails(to lines: inout [String]) {
        lines.append("App Group")

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

        if let userDefaults = UserDefaults(suiteName: ChronomarkModelContainerFactory.appGroupIdentifier) {
            lines.append("Migration marker: \(userDefaults.integer(forKey: migrationCompletedVersionKey))")
        } else {
            lines.append("Migration marker: unavailable")
        }
    }

    private static func appendLegacyStoreDetails(to lines: inout [String]) {
        lines.append("Legacy Store")

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
    }

    @MainActor
    private static func appendCurrentStoreCounts(
        modelContext: ModelContext?,
        to lines: inout [String]
    ) {
        lines.append("Current Model Context Counts")

        guard let modelContext else {
            lines.append("Unavailable")
            return
        }

        appendCounts(modelContext: modelContext, to: &lines)
    }

    @MainActor
    private static func appendSharedStoreCounts(to lines: inout [String]) {
        lines.append("Fresh Shared Store Counts")

        do {
            let context = try ModelContext(ChronomarkModelContainerFactory.makeSharedModelContainer())
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

    private static func topPresentedViewController(from viewController: UIViewController) -> UIViewController {
        var topViewController = viewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}
