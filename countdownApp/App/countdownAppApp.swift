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
//  DEBUG ONLY: Cmd+Shift+D injects fake corrupt fragments into corruptedDump
//  and broadcasts DebugNotifications.injectCorruptBanner so all three views
//  refresh their banner state immediately. Use for manual screenshot capture.
//

import SwiftUI
import CoreText
import AppKit

// MARK: - App delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        UserDefaults.standard.synchronize()
    }
}

// MARK: - App entry point

@main
struct countdownAppApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sunService = SunTimesService()
    @AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0

    init() {
        // Self-heal AppleLanguages: if the system-level override got lost (fresh app
        // container after a rebuild, external reset, etc.) while preferredLanguage
        // is still persisted, re-derive AppleLanguages from it here so the *next*
        // launch shows the correct language again instead of silently staying English.
        AppKeys.syncAppleLanguagesOverride()
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sunService)
                .dynamicTypeSize(fontSizeStep.asDynamicTypeSize)
        }
        .windowResizability(.contentSize)
        .commands {
            AboutCommands()
            HelpCommands()
            #if DEBUG
            CommandMenu("Debug") {
                Button("Inject corrupt banner") {
                    let fakeFragments = [
                        "{\"id\":\"00000000-0000-0000-0000-000000000001\",\"label\":\"Work deadline\",\"deadline\":1999999999,\"notes\":\"important meeting\"}",
                        "{\"id\":\"00000000-0000-0000-0000-000000000002\",\"label\":\"Gym session\",\"deadline\":\"not-a-date\",\"notes\":\"leg day\"}",
                        "{\"id\":\"00000000-0000-0000-0000-000000000003\",\"title\":\"Q4 review\",\"project\":\"Work\",\"body\":\"\\u00ef\\u00bf\\u00bd broken utf\"}"
                    ]
                    AppKeys.appendCorruptFragments(fakeFragments)
                    NotificationCenter.default.post(name: DebugNotifications.injectCorruptBanner, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }

        // ENH-SETTINGS-1: Preferences window (App menu → Preferences, Cmd+,)
        Settings {
            SettingsView()
        }
        .defaultSize(width: 440, height: 260)

        // ENH-ABOUT-1: custom About panel (App menu → About NightShift)
        WindowGroup(id: AboutWindowID.id) {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 400)

        // ENH-HELP-1-S2: Help window (Help menu → NightShift Help, Cmd+Shift+/)
        WindowGroup(id: HelpWindowID.id) {
            NavigationStack {
                HelpView()
            }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 640, height: 620)
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

// MARK: - DynamicTypeSize helper

private extension Int {
    /// Maps the stored font-size step (0–3) to a SwiftUI DynamicTypeSize.
    /// Only semantic fonts (.body, .headline, etc.) respond to this;
    /// Font.custom() calls with explicit sizes remain unchanged — intentional.
    var asDynamicTypeSize: DynamicTypeSize {
        switch self {
        case 1:  return .xLarge
        case 2:  return .xxLarge
        case 3:  return .xxxLarge
        default: return .large
        }
    }
}
