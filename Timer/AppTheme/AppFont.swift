//
//  AppFont.swift
//  Timer
//
//  Created by Anand Kumar on 5/9/26.
//

import UIKit

enum AppFont {
    case system
    case jetBrainsMono
    case manrope
    case spaceGrotesk
    
    func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let fontName = fontName(for: weight)
        return fontName.flatMap { UIFont(name: $0, size: size) } ?? fallbackRoundedFont(ofSize: size, weight: weight)
    }

    private func fontName(for weight: UIFont.Weight) -> String? {
        let rawWeight = weight.rawValue
        let fontWeight: FontWeight

        if rawWeight <= UIFont.Weight.light.rawValue {
            fontWeight = .light
        } else if rawWeight < UIFont.Weight.medium.rawValue {
            fontWeight = .regular
        } else if rawWeight < UIFont.Weight.semibold.rawValue {
            fontWeight = .medium
        } else if rawWeight < UIFont.Weight.bold.rawValue {
            fontWeight = .semibold
        } else {
            fontWeight = .bold
        }

        switch (self, fontWeight) {
        case (.system, _):
            return nil
        case (.jetBrainsMono, .light):
            return "JetBrainsMono-Light"
        case (.jetBrainsMono, .regular):
            return "JetBrainsMono-Regular"
        case (.jetBrainsMono, .medium):
            return "JetBrainsMono-Medium"
        case (.jetBrainsMono, .semibold):
            return "JetBrainsMono-SemiBold"
        case (.jetBrainsMono, .bold):
            return "JetBrainsMono-Bold"
        case (.manrope, .light):
            return "Manrope-Light"
        case (.manrope, .regular):
            return "Manrope-Regular"
        case (.manrope, .medium):
            return "Manrope-Medium"
        case (.manrope, .semibold):
            return "Manrope-SemiBold"
        case (.manrope, .bold):
            return "Manrope-Bold"
        case (.spaceGrotesk, .light):
            return "SpaceGrotesk-Light"
        case (.spaceGrotesk, .regular):
            return "SpaceGrotesk-Regular"
        case (.spaceGrotesk, .medium), (.spaceGrotesk, .semibold):
            return "SpaceGrotesk-Medium"
        case (.spaceGrotesk, .bold):
            return "SpaceGrotesk-Bold"
        }
    }
    
    private func fallbackRoundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
            return font
        }

        return UIFont(descriptor: descriptor, size: size)
    }

    private enum FontWeight {
        case light
        case regular
        case medium
        case semibold
        case bold
    }
}
