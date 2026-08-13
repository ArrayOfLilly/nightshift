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

    /// Warm amber background — the dominant color of the original Python Pomodoro tutorial app
    /// that this project is ported from. The color palette (amber, dark brown, purple tomato)
    /// was sampled directly from that app's reference design (timer_-_origin.png).
    ///
    /// Two amber candidates were evaluated side-by-side:
    ///   #E5A020 — original "Spooky Tomato" amber, sampled from the Python app's background.
    ///             Slightly darker and more mustard-toned.
    ///   #F5A623 — CSS amber already in use in markdownCSS (WKWebView rendered content).
    ///             Brighter, cleaner gold; preferred after visual comparison.
    ///
    /// Decision: #F5A623 wins. Original kept below for historical reference.
    // static let background = Color(red: 0xE5/255, green: 0xA0/255, blue: 0x20/255) // original Spooky Tomato amber
    static let background         = Color(red: 0xF5/255, green: 0xA6/255, blue: 0x23/255)
    /// Hex string version of `background` — used in markdownCSS so WebView amber matches SwiftUI.
    static let amberHex           = "#F5A623"
    /// Dark brown used for buttons and card text
    static let dark               = Color(red: 0.165, green: 0.125, blue: 0.082)
    /// Near-black background for Calculate mode (#060503)
    static let calculateBackground = Color(red: 0x06/255, green: 0x05/255, blue: 0x03/255)
    /// Semi-transparent dark overlay for cards / rows
    static let cardSurface        = Color(red: 0.165, green: 0.125, blue: 0.082).opacity(0.20)
    /// White — used for numerals displayed on the tomato body
    static let timerText   = Color.white

    /// Free-slot card color palette (12 options, rotated by item index)
    /// 30271B · 51422E · 778005 · 4D70D8 · 293B72 · 403873
    /// 593C73 · 723F73 · 8A4273 · DD3B72 · DD114A · B70E26
    static let freeColors: [Color] = [
        Color(red: 0x30/255, green: 0x27/255, blue: 0x1B/255), // 0  #30271B dark brown
        Color(red: 0x51/255, green: 0x42/255, blue: 0x2E/255), // 1  #51422E lighter brown
        Color(red: 0x77/255, green: 0x80/255, blue: 0x05/255), // 2  #778005 olive-yellow
        Color(red: 0x4D/255, green: 0x70/255, blue: 0xD8/255), // 3  #4D70D8 blue
        Color(red: 0x29/255, green: 0x3B/255, blue: 0x72/255), // 4  #293B72 navy
        Color(red: 0x40/255, green: 0x38/255, blue: 0x73/255), // 5  #403873 dark purple
        Color(red: 0x52/255, green: 0x35/255, blue: 0x54/255), // 6  #523554 dark red purple
        Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255), // 7  #593C73 purple
        Color(red: 0x72/255, green: 0x3F/255, blue: 0x73/255), // 8  #723F73 mid purple
        Color(red: 0x8A/255, green: 0x42/255, blue: 0x73/255), // 9  #8A4273 magenta-purple
        Color(red: 0x86/255, green: 0x54/255, blue: 0x86/255), // 10 #865486 magenta-purple 2
        Color(red: 0xDD/255, green: 0x3B/255, blue: 0x72/255), // 11 #DD3B72 pink-red
        Color(red: 0xDD/255, green: 0x11/255, blue: 0x4A/255), // 12 #DD114A hot red-pink
        Color(red: 0xB7/255, green: 0x0E/255, blue: 0x26/255), // 13 #B70E26 deep red
    ]

    /// Returns the free-slot color for the given index (cycles through freeColors)
    static func freeColor(for index: Int) -> Color {
        freeColors[index % freeColors.count]
    }

    // MARK: - Corner Radii

    /// Small radius — stepper buttons, compact badges (consolidates 5 and 6)
    static let radiusSmall:  CGFloat = 5
    /// Medium radius — standard buttons and input fields (consolidates 7 and 8)
    static let radiusMedium: CGFloat = 7
    /// Large radius — section containers and main cards (consolidates 12 and 14)
    static let radiusLarge:  CGFloat = 12

    // MARK: - Alpha

    /// Divider lines and barely-visible backgrounds (consolidates 0.07 and 0.08)
    static let alpha08: CGFloat = 0.08
    /// Button and field backgrounds — most common surface tint (consolidates 0.10 and 0.12)
    static let alpha12: CGFloat = 0.12
    /// Light overlay — fills and subtle highlights
    static let alpha25: CGFloat = 0.25
    /// Soft overlay — gradient stops and secondary fills
    static let alpha35: CGFloat = 0.35
    /// Muted text and mid-opacity elements (consolidates 0.45 and 0.50)
    static let alpha50: CGFloat = 0.50
    /// Clear-ish tints and icon fills (consolidates 0.55 and 0.60)
    static let alpha60: CGFloat = 0.60
    /// Strong tints and active state fills (consolidates 0.70 and 0.80)
    static let alpha75: CGFloat = 0.75
    /// Near-opaque elements — selected states and high-contrast labels (consolidates 0.85 and 0.90)
    static let alpha90: CGFloat = 0.90

    // MARK: - Window

    /// Minimum main window width — prevents content from collapsing below a usable layout
    static let windowMinWidth: CGFloat = 460
    /// Maximum main window width — keeps steppers and list rows from spreading out on wide displays
    /// Reference: MBP M4 14" at 1800×1169; app fills ~500–520pt of the available space comfortably
    static let windowMaxWidth: CGFloat = 520

    // MARK: - Gradients

    /// Shared gradient background for CALC-SAVE sheets and popovers.
    /// Purple tint (freeColors[7] @ 35%) fades into calculateBackground by 25% of the view height.
    static let calcSaveGradient = LinearGradient(
        stops: [
            .init(color: freeColors[7].opacity(alpha35), location: 0),
            .init(color: calculateBackground, location: 0.25),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

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
