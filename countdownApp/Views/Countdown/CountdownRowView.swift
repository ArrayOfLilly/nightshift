//
//  CountdownRowView.swift
//  countdownApp
//
//  Receives `now: Date` from the parent CountdownView's single TimelineView —
//  no per-row timer. This avoids N concurrent timers hammering the main thread.
//

import SwiftUI

struct CountdownRowView: View {

    @Binding var item: CountdownItem
    var now: Date = Date()
    var index: Int = 0
    @State private var copyFeedback: Bool = false

    private var itemFreeColor: Color {
        AppTheme.freeColor(for: item.accentColorIndex ?? 6)
    }

    var body: some View {
        rowContent(at: now)
    }

    @ViewBuilder
    private func rowContent(at now: Date) -> some View {
        let expired = item.isExpired(at: now)
        let accentColor: Color = expired ? itemFreeColor : AppTheme.cardSurface

        VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .center, spacing: 10) {

                HStack(spacing: 8) {
                    Text(copyFeedback ? "COPIED" : (item.label.isEmpty ? "—" : item.label))
                        .font(AppTheme.alienLeague(14))
                        .foregroundStyle(Color.white.opacity(copyFeedback ? 0.5 : 0.8))
                        .lineLimit(1)
                    if !copyFeedback && !item.notes.isEmpty {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.noteIndicator)
                            .accessibilityHidden(true)
                    }
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))
                .simultaneousGesture(TapGesture().onEnded {
                    let trimmed = item.label.trimmingCharacters(in: .whitespaces)
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(trimmed, forType: .string)
                    #else
                    UIPasteboard.general.string = trimmed
                    #endif
                    copyFeedback = true
                    Task {
                        try? await Task.sleep(for: .milliseconds(1000))
                        copyFeedback = false
                    }
                })

                if expired {
                    Text("FREE ✓")
                        .font(AppTheme.alienLeagueBold(13))
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha90))
                } else {
                    Button { item.showRemaining.toggle() } label: {
                        Image(systemName: item.showRemaining ? "calendar" : "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha90))
                            .frame(width: 42, height: 28)
                            .background(Color.white.opacity(AppTheme.alpha12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .accessibilityLabel(item.showRemaining ? "Switch to date display" : "Switch to remaining time")
                }
            }

            if !expired {
                if item.showRemaining {
                    Text(item.remainingFormatted(at: now))
                        .font(AppTheme.alienLeagueBold(24))
                        .foregroundStyle(AppTheme.dark.opacity(0.95))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.leading, 4)
                } else {
                    Text(item.deadlineFormatted)
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha90))
                        .lineLimit(1)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(16)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .shadow(
            color: expired ? itemFreeColor.opacity(AppTheme.alpha60) : .clear,
            radius: 10, x: 0, y: 0
        )
    }
}
