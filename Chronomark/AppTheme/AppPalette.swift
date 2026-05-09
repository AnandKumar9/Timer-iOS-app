//
//  AppPalette.swift
//  Timer
//
//  Created by Anand Kumar on 5/9/26.
//

import UIKit

protocol AppPalette {
    static var accent: UIColor { get }
    static var paused: UIColor { get }
    static var completed: UIColor { get }
    static var destructive: UIColor { get }
    static var screenBackground: UIColor { get }
    static var controlBackground: UIColor { get }
    static var cardBackground: UIColor { get }
    static var primaryText: UIColor { get }
    static var metadataText: UIColor { get }
    static var durationText: UIColor { get }
    static var tagText: UIColor { get }
    static var separator: UIColor { get }
    static var chipBorder: UIColor { get }
    static var runningDigitText: UIColor { get }

    static func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}

extension AppPalette {

    static func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
            return font
        }

        return UIFont(descriptor: descriptor, size: size)
    }
}

enum PurplePalette: AppPalette {
    static let accent = color(named: "ThemePurpleAccent")
    static let paused = color(named: "ThemePurplePaused")
    static let completed = color(named: "ThemePurpleCompleted")
    static let destructive = color(named: "ThemePurpleDestructive")
    static let screenBackground = color(named: "ThemePurpleScreenBackground")
    static let controlBackground = color(named: "ThemePurpleControlBackground")
    static let cardBackground = color(named: "ThemePurpleCardBackground")
    static let primaryText = color(named: "ThemePurplePrimaryText")
    static let metadataText = color(named: "ThemePurpleMetadataText")
    static let durationText = color(named: "ThemePurpleDurationText")
    static let tagText = color(named: "ThemePurpleTagText")
    static let separator = color(named: "ThemePurpleSeparator")
    static let chipBorder = color(named: "ThemePurpleChipBorder")
    static let runningDigitText = color(named: "ThemePurpleRunningDigitText")

    private static func color(named name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Missing color asset named \(name)")
            return .systemPink
        }

        return color
    }
}

enum TealPalette: AppPalette {
    static let accent = color(named: "ThemeTealAccent")
    static let paused = color(named: "ThemeTealPaused")
    static let completed = color(named: "ThemeTealCompleted")
    static let destructive = color(named: "ThemeTealDestructive")
    static let screenBackground = color(named: "ThemeTealScreenBackground")
    static let controlBackground = color(named: "ThemeTealControlBackground")
    static let cardBackground = color(named: "ThemeTealCardBackground")
    static let primaryText = color(named: "ThemeTealPrimaryText")
    static let metadataText = color(named: "ThemeTealMetadataText")
    static let durationText = color(named: "ThemeTealDurationText")
    static let tagText = color(named: "ThemeTealTagText")
    static let separator = color(named: "ThemeTealSeparator")
    static let chipBorder = color(named: "ThemeTealChipBorder")
    static let runningDigitText = color(named: "ThemeTealRunningDigitText")

    private static func color(named name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Missing color asset named \(name)")
            return .systemPink
        }

        return color
    }
}

enum CoralPalette: AppPalette {
    static let accent = color(named: "ThemeCoralAccent")
    static let paused = color(named: "ThemeCoralPaused")
    static let completed = color(named: "ThemeCoralCompleted")
    static let destructive = color(named: "ThemeCoralDestructive")
    static let screenBackground = color(named: "ThemeCoralScreenBackground")
    static let controlBackground = color(named: "ThemeCoralControlBackground")
    static let cardBackground = color(named: "ThemeCoralCardBackground")
    static let primaryText = color(named: "ThemeCoralPrimaryText")
    static let metadataText = color(named: "ThemeCoralMetadataText")
    static let durationText = color(named: "ThemeCoralDurationText")
    static let tagText = color(named: "ThemeCoralTagText")
    static let separator = color(named: "ThemeCoralSeparator")
    static let chipBorder = color(named: "ThemeCoralChipBorder")
    static let runningDigitText = color(named: "ThemeCoralRunningDigitText")

    private static func color(named name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Missing color asset named \(name)")
            return .systemPink
        }

        return color
    }
}

enum AppAccentColor: String, CaseIterable {
    case teal
    case purple
    case coral

    var displayName: String {
        switch self {
        case .teal:
            return "Teal"
        case .purple:
            return "Purple"
        case .coral:
            return "Coral"
        }
    }

    var palette: any AppPalette.Type {
        switch self {
        case .teal:
            return TealPalette.self
        case .purple:
            return PurplePalette.self
        case .coral:
            return CoralPalette.self
        }
    }

    var previewColor: UIColor {
        palette.accent
    }
}
