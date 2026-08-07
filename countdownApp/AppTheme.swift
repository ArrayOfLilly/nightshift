//
//  AppTheme.swift
//  countdownApp
//
//  "Spooky Tomato" visual theme.
//  Colors sampled from timer.png reference design.
//  Fonts: Alien League family — must be registered in Info.plist before use.
//

import SwiftUI

enum AppTheme {

    // MARK: - Colors

    /// Warm amber background (the dominant color in the reference design)
    static let background         = Color(red: 0.898, green: 0.627, blue: 0.125)
    /// Dark brown used for buttons and card text
    static let dark               = Color(red: 0.165, green: 0.125, blue: 0.082)
    /// Near-black background for Calculate mode (#060503)
    static let calculateBackground = Color(red: 0x06/255, green: 0x05/255, blue: 0x03/255)
    /// Semi-transparent dark overlay for cards / rows
    static let cardSurface        = Color(red: 0.165, green: 0.125, blue: 0.082).opacity(0.20)
    /// White — used for numerals displayed on the tomato body
    static let timerText   = Color.white

    /// Free-slot card color palette (11 options, rotated by item index)
    /// 778005 · 30271B · 293B72 · 4D70D8 · 403873
    /// 593C73 · 8A4273 · 723F73 · DD3B72 · DD114A · B70E26
    static let freeColors: [Color] = [
        Color(red: 0x30/255, green: 0x27/255, blue: 0x1B/255), // 2  #30271B dark brown
        Color(red: 0x51/255, green: 0x42/255, blue: 0x2E/255), // 1  #51422E lighter brown
        Color(red: 0x77/255, green: 0x80/255, blue: 0x05/255), // 0  #778005 olive-yellow
        Color(red: 0x4D/255, green: 0x70/255, blue: 0xD8/255), // 4  #4D70D8 blue
        Color(red: 0x29/255, green: 0x3B/255, blue: 0x72/255), // 3  #293B72 navy
        Color(red: 0x40/255, green: 0x38/255, blue: 0x73/255), // 5  #403873 dark purple
        Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255), // 6  #593C73 purple
        Color(red: 0x72/255, green: 0x3F/255, blue: 0x73/255), // 8  #723F73 mid purple
        Color(red: 0x8A/255, green: 0x42/255, blue: 0x73/255), // 7  #8A4273 magenta-purple
        Color(red: 0xDD/255, green: 0x3B/255, blue: 0x72/255), // 9  #DD3B72 pink-red
        Color(red: 0xDD/255, green: 0x11/255, blue: 0x4A/255), // 10 #DD114A hot red-pink
        Color(red: 0xB7/255, green: 0x0E/255, blue: 0x26/255), // 11 #B70E26 deep red
    ]

    /// Returns the free-slot color for the given index (cycles through freeColors)
    static func freeColor(for index: Int) -> Color {
        freeColors[index % freeColors.count]
    }

    // MARK: - Fonts
    // NOTE: If text appears in system font, verify the PostScript name in Font Book.
    // Open a .ttf with Font Book → Info tab → PostScript name.

    static func alienLeague(_ size: CGFloat) -> Font {
        Font.custom("Alien League", size: size)
    }

    static func alienLeagueBold(_ size: CGFloat) -> Font {
        Font.custom("Alien League Bold", size: size)
    }
}
