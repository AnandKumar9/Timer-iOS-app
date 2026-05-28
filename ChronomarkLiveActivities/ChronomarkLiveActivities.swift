import AppIntents
import ActivityKit
import SwiftUI
import WidgetKit

struct ChronomarkLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
            ActivityConfiguration(for: ChronomarkTimerAttributes.self) { context in
                ChronomarkLockScreenLiveActivityView(context: context)
                    .widgetURL(Self.timerURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    ChronomarkLiveActivityRow(context: context)
                        .padding(.horizontal, 18)
                }
            }
                compactLeading: {
                    Image(systemName: Self.iconName(for: context.state.status))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Self.timerTextColor(for: context.state))
                }
                compactTrailing: {
                    ChronomarkElapsedTimeText(state: context.state)
                        .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Self.timerTextColor(for: context.state))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 46, alignment: .trailing)
                }
                minimal: {
                    Image(systemName: Self.iconName(for: context.state.status))
                        .foregroundStyle(Self.timerTextColor(for: context.state))
                }
            .keylineTint(Color.chronomarkClockOrange)
            .widgetURL(Self.timerURL)
        }
    }

    private static let timerURL = URL(string: "chronomark://timer")
    static let activityNameFontSize: CGFloat = 20

    static func formattedTime(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let seconds = seconds % 60
        guard hours > 0 else {
            return String(format: "%d:%02d", minutes, seconds)
        }

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func iconName(for status: String) -> String {
        status.isPausedStatus ? "pause.circle.fill" : "timer"
    }

    static func timerTextColor(for state: ChronomarkTimerAttributes.ContentState) -> Color {
        state.status.isPausedStatus ? .chronomarkPausedTimer : .chronomarkRunningTimer
    }

    static func timerTextWidth(for state: ChronomarkTimerAttributes.ContentState) -> CGFloat {
        state.elapsedSeconds >= 3_600 ? 98 : 68
    }

    static func activityNameFont(for state: ChronomarkTimerAttributes.ContentState) -> Font {
        ChronomarkLiveActivityFont.resolved(rawValue: state.fontRawValue)
            .font(size: activityNameFontSize, weight: .regular)
    }

    static func elapsedTimeFont(
        for state: ChronomarkTimerAttributes.ContentState,
        size: CGFloat
    ) -> Font {
        ChronomarkLiveActivityFont.resolved(rawValue: state.fontRawValue)
            .font(size: size, weight: .semibold)
            .monospacedDigit()
    }
}

private struct ChronomarkLockScreenLiveActivityView: View {
    let context: ActivityViewContext<ChronomarkTimerAttributes>

    var body: some View {
        VStack(spacing: 16) {
            ChronomarkLiveActivityRow(context: context)
            ChronomarkLiveActivityControlRow(state: context.state)
        }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
    }
}

private struct ChronomarkLiveActivityControlRow: View {
    let state: ChronomarkTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            if state.status.isPausedStatus {
                ChronomarkLiveActivityControlButton(
                    title: "Resume",
                    systemImage: "play.fill",
                    state: state,
                    foregroundColor: .chronomarkPrimaryButtonText,
                    backgroundColor: ChronomarkLiveActivityAccentColor
                        .resolved(rawValue: state.accentColorRawValue)
                        .accent
                        .opacity(0.14),
                    intent: ChronomarkLiveActivityResumeIntent()
                )
            } else {
                ChronomarkLiveActivityControlButton(
                    title: "Pause",
                    systemImage: "pause.fill",
                    state: state,
                    foregroundColor: .chronomarkPrimaryButtonText,
                    backgroundColor: ChronomarkLiveActivityAccentColor
                        .resolved(rawValue: state.accentColorRawValue)
                        .paused
                        .opacity(0.22),
                    intent: ChronomarkLiveActivityPauseIntent()
                )
            }

            ChronomarkLiveActivityControlButton(
                title: "Stop",
                systemImage: "stop.fill",
                state: state,
                foregroundColor: .chronomarkStopButton,
                backgroundColor: .chronomarkStopButtonBackground,
                intent: ChronomarkLiveActivityStopIntent()
            )
        }
        .frame(height: 46)
    }
}

private struct ChronomarkLiveActivityControlButton<Intent: AppIntent>: View {
    let title: String
    let systemImage: String
    let state: ChronomarkTimerAttributes.ContentState
    let foregroundColor: Color
    let backgroundColor: Color
    let intent: Intent

    var body: some View {
        Button(intent: intent) {
            Label(title, systemImage: systemImage)
                .font(
                    ChronomarkLiveActivityFont
                        .resolved(rawValue: state.fontRawValue)
                        .font(size: 16, weight: .regular)
                )
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct ChronomarkLiveActivityPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"

    func perform() async throws -> some IntentResult {
        print("Chronomark live activity Pause tapped")
        return .result()
    }
}

private struct ChronomarkLiveActivityResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"

    func perform() async throws -> some IntentResult {
        print("Chronomark live activity Resume tapped")
        return .result()
    }
}

private struct ChronomarkLiveActivityStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"

    func perform() async throws -> some IntentResult {
        print("Chronomark live activity Stop tapped")
        return .result()
    }
}

private struct ChronomarkLiveActivityRow: View {
    let context: ActivityViewContext<ChronomarkTimerAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image("LiveActivityAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .layoutPriority(3)

            Text(context.state.activityName)
                .font(ChronomarkLiveActivityWidget.activityNameFont(for: context.state))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .truncationMode(.tail)
                .layoutPriority(0)

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                Image(systemName: ChronomarkLiveActivityWidget.iconName(for: context.state.status))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(ChronomarkLiveActivityWidget.timerTextColor(for: context.state))
                    .frame(width: 18, alignment: .center)

                ChronomarkElapsedTimeText(state: context.state)
                    .font(ChronomarkLiveActivityWidget.elapsedTimeFont(for: context.state, size: 21))
                    .foregroundStyle(ChronomarkLiveActivityWidget.timerTextColor(for: context.state))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: ChronomarkLiveActivityWidget.timerTextWidth(for: context.state), alignment: .trailing)
            }
            .frame(width: ChronomarkLiveActivityWidget.timerTextWidth(for: context.state) + 23, alignment: .trailing)
            .layoutPriority(3)
        }
        .font(.caption.weight(.regular))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum ChronomarkLiveActivityFont: String {
    case jetBrainsMono
    case manrope

    func font(size: CGFloat, weight: ChronomarkLiveActivityFontWeight) -> Font {
        .custom(fontName(for: weight), size: size)
    }

    private func fontName(for weight: ChronomarkLiveActivityFontWeight) -> String {
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

    static func resolved(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .manrope
    }
}

private enum ChronomarkLiveActivityFontWeight {
    case regular
    case semibold
}

private enum ChronomarkLiveActivityAccentColor: String {
    case teal
    case purple
    case coral

    var accent: Color {
        switch self {
        case .teal:
            return Color(red: 0x2D / 255, green: 0xD4 / 255, blue: 0xBF / 255)
        case .purple:
            return Color(red: 0x6C / 255, green: 0x63 / 255, blue: 0xF5 / 255)
        case .coral:
            return Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x5F / 255)
        }
    }

    var paused: Color {
        switch self {
        case .teal, .purple:
            return Color(red: 0xF5 / 255, green: 0xA6 / 255, blue: 0x23 / 255)
        case .coral:
            return Color(red: 0xF2 / 255, green: 0xB8 / 255, blue: 0x4B / 255)
        }
    }

    static func resolved(rawValue: String) -> Self {
        Self(rawValue: rawValue) ?? .teal
    }
}

private struct ChronomarkElapsedTimeText: View {
    let state: ChronomarkTimerAttributes.ContentState

    var body: some View {
        if
            !state.status.isPausedStatus,
            let timerStartDate = state.timerStartDate {
            Text(timerStartDate, style: .timer)
                .monospacedDigit()
                .contentTransition(.numericText())
        } else {
            Text(ChronomarkLiveActivityWidget.formattedTime(state.elapsedSeconds))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }
}

private extension Color {
    static let chronomarkLiveActivityBackground = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let chronomarkClockOrange = Color(red: 1.0, green: 0.64, blue: 0.20)
    static let chronomarkRunningTimer = Color(red: 0x7C / 255, green: 0xFF / 255, blue: 0xA4 / 255)
    static let chronomarkPausedTimer = Color(red: 0xF5 / 255, green: 0xA6 / 255, blue: 0x23 / 255)
    static let chronomarkStopButton = Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x6B / 255)
    static let chronomarkPrimaryButtonText = Color(red: 0xF7 / 255, green: 0xF4 / 255, blue: 0xEE / 255)
    static let chronomarkStopButtonBackground = Color.white.opacity(0.10)
}

private extension String {
    var isPausedStatus: Bool {
        localizedCaseInsensitiveContains("paused")
    }
}

@main
struct ChronomarkLiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        ChronomarkLiveActivityWidget()
    }
}

#Preview("Lock Screen", as: .content, using: ChronomarkTimerAttributes(activityTypeUniqueID: UUID(), activityName: "Focus Session")) {
    ChronomarkLiveActivityWidget()
} contentStates: {
    ChronomarkTimerAttributes.ContentState(
        activityName: "Focus Session",
        elapsedSeconds: 1_245,
        status: "Running",
        timerStartDate: Date().addingTimeInterval(-1_245),
        fontRawValue: "manrope",
        accentColorRawValue: "teal"
    )
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: ChronomarkTimerAttributes(activityTypeUniqueID: UUID(), activityName: "Morning commut§e - Dranesville Road")) {
    ChronomarkLiveActivityWidget()
} contentStates: {
    ChronomarkTimerAttributes.ContentState(
        activityName: "Morning commut§e - Dranesville Road",
        elapsedSeconds: 1_245,
        status: "Running",
        timerStartDate: Date().addingTimeInterval(-1_245),
        fontRawValue: "jetBrainsMono",
        accentColorRawValue: "teal"
    )
}
