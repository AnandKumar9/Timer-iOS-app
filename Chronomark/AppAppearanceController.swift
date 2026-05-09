import UIKit

enum AppAppearanceMode: String {
    case system
    case light
    case dark

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppAppearanceController {
    private static let userDefaultsKey = "selectedAppAppearance"

    static var savedAppearanceMode: AppAppearanceMode {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
            let storedAppearance = AppAppearanceMode(rawValue: rawValue)
        else {
            return .system
        }

        return storedAppearance
    }

    static var savedUserInterfaceStyle: UIUserInterfaceStyle {
        savedAppearanceMode.userInterfaceStyle
    }

    static func applySavedAppearance(to window: UIWindow) {
        window.overrideUserInterfaceStyle = savedUserInterfaceStyle
    }

    static func toggleAppearance(from currentStyle: UIUserInterfaceStyle) {
        let nextAppearance: AppAppearanceMode = currentStyle == .dark ? .light : .dark
        setAppearanceMode(nextAppearance)
    }

    static func setAppearance(_ style: UIUserInterfaceStyle) {
        let nextAppearance: AppAppearanceMode = style == .dark ? .dark : .light
        setAppearanceMode(nextAppearance)
    }

    static func setAppearanceMode(_ mode: AppAppearanceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: userDefaultsKey)
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
