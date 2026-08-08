//
//  countdownAppApp.swift
//  countdownApp
//
//  App entry point. Single WindowGroup wrapping ContentView,
//  which owns the Calculate / Countdown mode switcher.
//

import SwiftUI

@main
struct countdownAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
