import ActivityKit
import Foundation

enum ChronomarkLiveActivityFont: String, Codable, Hashable {
    case jetBrainsMono
    case manrope

    static let defaultFont: Self = .manrope

    init(rawValueOrDefault rawValue: String) {
        self = Self(rawValue: rawValue) ?? Self.defaultFont
    }

    func fontName(for weight: ChronomarkLiveActivityFontWeight) -> String {
        switch (self, weight) {
        case (.jetBrainsMono, .regular):
            return "JetBrainsMono-Regular"
        case (.jetBrainsMono, .semibold):
            return "JetBrainsMono-SemiBold"
        case (.manrope, .regular):
            return "Manrope-Regular"
        case (.manrope, .semibold):
            return "Manrope-SemiBold"
        }
    }
}

enum ChronomarkLiveActivityFontWeight: String, Codable, Hashable {
    case regular
    case semibold
}

struct ChronomarkTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var activityName: String
        var elapsedSeconds: Int
        var status: String
        var timerStartDate: Date?
        var fontRawValue: String

        init(
            activityName: String,
            elapsedSeconds: Int,
            status: String,
            timerStartDate: Date?,
            fontRawValue: String = ChronomarkLiveActivityFont.defaultFont.rawValue
        ) {
            self.activityName = activityName
            self.elapsedSeconds = elapsedSeconds
            self.status = status
            self.timerStartDate = timerStartDate
            self.fontRawValue = fontRawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            activityName = try container.decode(String.self, forKey: .activityName)
            elapsedSeconds = try container.decode(Int.self, forKey: .elapsedSeconds)
            status = try container.decode(String.self, forKey: .status)
            timerStartDate = try container.decodeIfPresent(Date.self, forKey: .timerStartDate)
            fontRawValue = try container.decodeIfPresent(String.self, forKey: .fontRawValue)
                ?? ChronomarkLiveActivityFont.defaultFont.rawValue
        }
    }

    var activityTypeUniqueID: UUID
    var activityName: String
}
