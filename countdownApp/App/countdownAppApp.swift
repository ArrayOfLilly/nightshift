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

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sunService)
        }
        .windowResizability(.contentSize)
        #if DEBUG
        .commands {
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
        }
        #endif
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
