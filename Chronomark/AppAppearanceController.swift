import UIKit

enum AppAppearanceController {
    private enum StoredAppearance: String {
        case light
        case dark

        var userInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    private static let userDefaultsKey = "selectedAppAppearance"

    static var savedUserInterfaceStyle: UIUserInterfaceStyle {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
            let storedAppearance = StoredAppearance(rawValue: rawValue)
        else {
            return .unspecified
        }

        return storedAppearance.userInterfaceStyle
    }

    static func applySavedAppearance(to window: UIWindow) {
        window.overrideUserInterfaceStyle = savedUserInterfaceStyle
    }

    static func toggleAppearance(from currentStyle: UIUserInterfaceStyle) {
        let nextAppearance: StoredAppearance = currentStyle == .dark ? .light : .dark
        setAppearance(nextAppearance.userInterfaceStyle)
    }

    static func setAppearance(_ style: UIUserInterfaceStyle) {
        let nextAppearance: StoredAppearance = style == .dark ? .dark : .light
        UserDefaults.standard.set(nextAppearance.rawValue, forKey: userDefaultsKey)
        applySavedAppearanceToConnectedWindows()
        AppTheme.applyThemeChange()
    }

    private static func applySavedAppearanceToConnectedWindows() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach(applySavedAppearance)
    }
}
