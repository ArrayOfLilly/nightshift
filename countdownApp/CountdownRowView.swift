//
//  CountdownRowView.swift
//  countdownApp
//
//  A single countdown entry card.
//  Uses TimelineView to tick every second when showing remaining time.
//  Binding<CountdownItem> allows the toggle state to propagate back to the list.
//  Free-slot background color is picked from AppTheme.freeColors based on item UUID hash.
//  Layout: outer accent ring (padding 5, cornerRadius 18) wraps a full-width dark pill
//  (cornerRadius 12) containing label + copy icon + Spacer + time/FREE text.
//  Toggle button sits outside the pill on the accent ring, right side, non-expired only.
//  Expired rows: pill spans the full width alone, no toggle.
//  Copy button uses simultaneousGesture so the parent NavigationLink still fires on tap.
//

import SwiftUI

struct CountdownRowView: View {

    @Binding var item: CountdownItem
    var index: Int = 0
    @State private var copyFeedback: Bool = false

    /// Stable color per item derived from UUID hash — cycles through AppTheme.freeColors
    private var itemFreeColor: Color {
        AppTheme.freeColor(for: abs(item.id.hashValue))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            rowContent(at: ctx.date)
        }
    }

    // MARK: - Row content

    @ViewBuilder
    private func rowContent(at now: Date) -> some View {
        let expired = item.isExpired(at: now)
        let accentColor: Color = expired ? itemFreeColor : AppTheme.cardSurface

        VStack(alignment: .leading, spacing: 6) {

            // ── Top row: dark pill + toggle/FREE ──
            HStack(alignment: .center, spacing: 10) {

                // Dark pill — tapping anywhere copies the label
                HStack(spacing: 8) {
                    Text(copyFeedback ? "COPIED" : (item.label.isEmpty ? "—" : item.label))
                        .font(AppTheme.alienLeague(14))
                        .foregroundStyle(Color.white.opacity(copyFeedback ? 0.5 : 0.8))
                        .lineLimit(1)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .simultaneousGesture(TapGesture().onEnded {
                    let trimmed = item.label.trimmingCharacters(in: .whitespaces)
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(trimmed, forType: .string)
                    #else
                    UIPasteboard.general.string = trimmed
                    #endif
                    copyFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        copyFeedback = false
                    }
                })

                // Right side: toggle (non-expired) or FREE badge (expired)
                if expired {
                    Text("FREE ✓")
                        .font(AppTheme.alienLeagueBold(13))
                        .foregroundStyle(Color.white.opacity(0.9))
                } else {
                    Button { item.showRemaining.toggle() } label: {
                        Image(systemName: item.showRemaining ? "calendar" : "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.dark.opacity(0.85))
                            .frame(width: 42, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                }
            }

            // ── Bottom: time/date — on the accent ring, below the pill ──
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
                        .foregroundStyle(AppTheme.dark.opacity(0.9))
                        .lineLimit(1)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(16)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: expired ? itemFreeColor.opacity(0.55) : .clear,
            radius: 10, x: 0, y: 0
        )
    }

}
