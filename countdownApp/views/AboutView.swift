//
//  AboutView.swift
//  countdownApp
//
//  Custom About panel — App menu → About NightShift
//
//  Responsibilities:
//  - Display app icon, name, version and build number
//  - Credit image assets (Freepik, attribution required)
//  - Provide contact email as mailto: link
//  - Show author footer
//
//  Architectural role:
//  - Pure presentation layer; no store or service access
//  - Opened via WindowGroup(id: AboutWindowID.id), triggered from
//    CommandGroup(replacing: .appInfo) in countdownAppApp
//
//  Image credits:
//  Moon and sun assets: Freepik (https://www.freepik.com)
//  Attribution required by Freepik Free License.
//
//  ENH-ABOUT-1 (BG session): initial implementation, iconKeeper AboutView as reference
//

import SwiftUI

// MARK: - Window ID

enum AboutWindowID {
    static let id = "nightshift-about"
}

// MARK: - Commands

struct AboutCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About NightShift") {
                openWindow(id: AboutWindowID.id)
            }
        }
    }
}

// MARK: - View

struct AboutView: View {

    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-" }
    private var build:   String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-" }

    var body: some View {
        VStack(spacing: 0) {

            // Header — icon + name + version
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack(spacing: 4) {
                    Text("NightShift")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(String(format: String(localized: "Version %@ (%@)"), version, build))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Content — info rows
            VStack(alignment: .leading, spacing: 24) {
                Text("A sideproject management tool built for late-night focus sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 18) {
                    infoRow(label: "Developer", value: "Kasza Ildikó") {
                        NSWorkspace.shared.open(URL(string: "mailto:arrayoflilly@gmail.com")!)
                    }
                    infoRow(label: "Images", value: "Freepik") {
                        NSWorkspace.shared.open(URL(string: "https://www.freepik.com")!)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))

            // Footer
            Text("© 2026 ArrayOfLilly")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.vertical, 20)
        }
        .frame(width: 300)
        .background(.thinMaterial)
        .onAppear {
            if let window = NSApplication.shared.windows.first(where: { $0.title == "NightShift" }) {
                window.isExcludedFromWindowsMenu = true
            }
        }
        .focusable(false)
    }

    @ViewBuilder
    private func infoRow(label: LocalizedStringKey, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .textCase(.uppercase)
                .font(.system(.caption2, weight: .bold))
                .foregroundStyle(.secondary)
            Button(action: action) {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
    }
}
