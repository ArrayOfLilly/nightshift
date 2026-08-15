//
//  SettingsView.swift
//  countdownApp
//
//  Application settings panel — opened via App menu → Preferences (Cmd+,).
//  Hosted in the native SwiftUI Settings scene (no custom window ID required).
//
//  Two tabs (toolbar-style, macOS native):
//  - Language: Interface Language + Date & Number Format pickers.
//    Both require restart; restart advisory shown when either is non-default.
//  - Appearance: Font Size segmented picker, takes effect immediately.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            LanguageTab()
                .tabItem {
                    Label("Language", systemImage: "globe")
                }

            AppearanceTab()
                .tabItem {
                    Label("Appearance", systemImage: "textformat.size")
                }
        }
        .frame(width: 440)
    }
}

// MARK: - Language tab

private struct LanguageTab: View {

    @AppStorage(AppKeys.preferredLanguage) private var preferredLanguage: String = ""
    @AppStorage(AppKeys.preferredLocale)   private var preferredLocale:   String = ""

    private var restartNeeded: Bool {
        !preferredLanguage.isEmpty || !preferredLocale.isEmpty
    }

    var body: some View {
        Form {
            Section {
                Picker("Interface Language", selection: $preferredLanguage) {
                    Text("System Default").tag("")
                    Divider()
                    ForEach(supportedLanguages, id: \.tag) { lang in
                        Text(lang.displayName).tag(lang.tag)
                    }
                }
                .onChange(of: preferredLanguage) { tag, _ in
                    applyLanguageOverride(tag)
                }

                Picker("Date & Number Format", selection: $preferredLocale) {
                    Text("System Default").tag("")
                    Divider()
                    ForEach(supportedLocales, id: \.tag) { loc in
                        Text(loc.displayName).tag(loc.tag)
                    }
                }
            }

            if restartNeeded {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundStyle(.secondary)
                        Text("Restart NightShift to apply language changes.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .frame(width: 440, height: restartNeeded ? 240 : 190)
    }

    private func applyLanguageOverride(_ tag: String) {
        if tag.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([tag], forKey: "AppleLanguages")
        }
    }

    private struct SupportedLanguage { let tag: String; let displayName: String }
    private struct SupportedLocale   { let tag: String; let displayName: String }

    private let supportedLanguages: [SupportedLanguage] = {
        let knownTags = ["en", "hu"]
        return knownTags.compactMap { tag -> SupportedLanguage? in
            let locale = Locale(identifier: tag)
            guard let name = locale.localizedString(forLanguageCode: tag) else { return nil }
            let capitalized = name.prefix(1).uppercased() + name.dropFirst()
            return SupportedLanguage(tag: tag, displayName: capitalized)
        }
    }()

    private let supportedLocales: [SupportedLocale] = [
        SupportedLocale(tag: "en_US", displayName: "English (US)"),
        SupportedLocale(tag: "hu_HU", displayName: "Magyar (HU)"),
    ]
}

// MARK: - Appearance tab

private struct AppearanceTab: View {

    @AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0

    var body: some View {
        Form {
            Section {
                Picker("Font Size", selection: $fontSizeStep) {
                    Text("Default").tag(0)
                    Text("Large").tag(1)
                    Text("Larger").tag(2)
                    Text("Largest").tag(3)
                }
                .pickerStyle(.segmented)
            } footer: {
                Text("Adjusts text size throughout the app. Takes effect immediately.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .frame(width: 440, height: 160)
    }
}

#Preview {
    SettingsView()
}
