import Foundation

enum ActivityDisplayFormatter {
    private static let recentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM dd (EEE) hh:mm a"
        return formatter
    }()

    private static let olderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"
        return formatter
    }()

    static func activityDateText(for date: Date, relativeTo referenceDate: Date = Date()) -> String {
        if let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: referenceDate),
           date < oneYearAgo {
            return olderDateFormatter.string(from: date)
        }

        return recentDateFormatter.string(from: date)
    }

    static func activityDateWithoutTimeText(
        for date: Date,
        relativeTo referenceDate: Date = Date(),
        includesWeekday: Bool = true
    ) -> String {
        if let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: referenceDate),
           date < oneYearAgo {
            return olderDateFormatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = includesWeekday ? "MM dd (EEE)" : "MM dd"
        return formatter.string(from: date)
    }

    static func roundedHourMinuteDurationText(for duration: TimeInterval) -> String {
        if AppSettings.showDurationSeconds {
            return durationTextIncludingSeconds(for: duration)
        }

        let seconds = max(0, duration)

        guard seconds >= 60 else {
            return "< 1 min"
        }

        let totalMinutes = Int(ceil(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }

        return "\(totalMinutes) min"
    }

    static func roundedHistoryDurationText(for duration: TimeInterval) -> String {
        if AppSettings.showDurationSeconds {
            return durationTextIncludingSeconds(for: duration)
        }

        let seconds = max(0, duration)
        let totalMinutes = max(1, Int(ceil(seconds / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }

        return "\(totalMinutes) min"
    }

    private static func durationTextIncludingSeconds(for duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min \(seconds) sec"
        }

        if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        }

        return "\(seconds) sec"
    }
}
