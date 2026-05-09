import UIKit

enum AppTheme: AppPalette {

    static let AppFont: AppFont = .system
    static let palette: any AppPalette.Type = TealPalette.self
    
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
        return AppFont.roundedFont(ofSize: size, weight: weight)
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
