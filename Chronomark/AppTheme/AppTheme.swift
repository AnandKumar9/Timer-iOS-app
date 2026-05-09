import UIKit

enum AppTheme: AppPalette {

    static let didChangeNotification = Notification.Name("AppThemeDidChangeNotification")

    private static let selectedFontKey = "selectedAppFont"
    private static let selectedAccentColorKey = "selectedAppAccentColor"

    static var selectedFont: AppFont {
        get {
            guard
                let rawValue = UserDefaults.standard.string(forKey: selectedFontKey),
                let font = AppFont(rawValue: rawValue)
            else {
                return .manrope
            }

            return font
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedFontKey)
            applyThemeChange()
        }
    }

    static var selectedAccentColor: AppAccentColor {
        get {
            guard
                let rawValue = UserDefaults.standard.string(forKey: selectedAccentColorKey),
                let accentColor = AppAccentColor(rawValue: rawValue)
            else {
                return .teal
            }

            return accentColor
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedAccentColorKey)
            applyThemeChange()
        }
    }

    static var palette: any AppPalette.Type {
        selectedAccentColor.palette
    }
    
    static var accent: UIColor { palette.accent }
    static var paused: UIColor { palette.paused }
    static var completed: UIColor { palette.completed }
    static var destructive: UIColor { palette.destructive }
    static var screenBackground: UIColor { palette.screenBackground }
    static var controlBackground: UIColor { palette.controlBackground }
    static var cardBackground: UIColor { palette.cardBackground }
    static var primaryText: UIColor { palette.primaryText }
    static var metadataText: UIColor { palette.metadataText }
    static var durationText: UIColor { palette.durationText }
    static var tagText: UIColor { palette.tagText }
    static var separator: UIColor { palette.separator }
    static var chipBorder: UIColor { palette.chipBorder }
    static var runningDigitText: UIColor { palette.runningDigitText }

    static func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return selectedFont.roundedFont(ofSize: size, weight: weight)
    }

    static func font(
        _ font: AppFont,
        ofSize size: CGFloat,
        weight: UIFont.Weight
    ) -> UIFont {
        font.roundedFont(ofSize: size, weight: weight)
    }

    static func applyThemeChange() {
        configureTypographyAppearance()
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func configureTypographyAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.titleTextAttributes = [
            .font: roundedFont(ofSize: 17, weight: .semibold),
            .foregroundColor: primaryText
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .font: roundedFont(ofSize: 34, weight: .bold),
            .foregroundColor: primaryText
        ]

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance

        UIBarButtonItem.appearance().setTitleTextAttributes(
            [.font: roundedFont(ofSize: 17, weight: .medium)],
            for: .normal
        )
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [.font: roundedFont(ofSize: 17, weight: .medium)],
            for: .highlighted
        )
    }
}
