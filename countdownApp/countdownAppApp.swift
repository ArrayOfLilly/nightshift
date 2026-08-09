//
//  countdownAppApp.swift
//  countdownApp
//
//  App entry point. Single WindowGroup wrapping ContentView,
//  which owns the Calculate / Countdown mode switcher.
//
//  Registers the bundled Alien League font files with CoreText at launch
//  (process scope only — no system-wide install), so Font.custom("Alien
//  League", …) resolves from inside the app bundle instead of depending
//  on the font being separately installed in Font Book.
//

import SwiftUI
import CoreText

@main
struct countdownAppApp: App {

    @StateObject private var sunService = SunTimesService()

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sunService)
        }
    }

    private static func registerBundledFonts() {
        let fileNames = ["alienleague", "alienleaguebold", "alienleagueital", "alienleaguebolditalic"]
        for name in fileNames {
            let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Font")
            guard let fontURL = url else {
                print("⚠️ countdownApp: font not found in bundle: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                let underlying = error?.takeRetainedValue().localizedDescription ?? "unknown error"
                // Already-registered is not a real failure (e.g. also present in Font Book).
                if !underlying.contains("already") {
                    print("⚠️ countdownApp: failed to register \(name).ttf — \(underlying)")
                }
            }
        }
    }
}
