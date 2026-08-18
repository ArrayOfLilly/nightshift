//
//  DeadlineDetailSheet.swift
//  countdownApp
//
//  Detail sheet for a saved NamedDeadline — presented via CalculateView's sheet(item:) on
//  CalculationModal.deadlineDetail. Owns its rename/delete sub-state.
//  Mutations are delegated back to CalculateView via callbacks (onLoad, onDelete, onRename).
//  Dismiss (X button) uses @Environment(\.dismiss) — no explicit callback needed.
//

import SwiftUI

@MainActor
struct DeadlineDetailSheet: View {

    let deadline: NamedDeadline
    let onLoad:   (NamedDeadline) -> Void
    let onDelete: (NamedDeadline) -> Void
    let onRename: (NamedDeadline, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isRenaming:        Bool    = false
    @State private var renameDraft:       String  = ""
    @State private var showDeleteConfirm: Bool    = false
    @State private var sheetWidth:        CGFloat = 400

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(Color.white.opacity(AppTheme.alpha08))
                .frame(height: 1)
                .padding(.horizontal, 28)
            if isRenaming { renameActions } else { normalActions }
        }
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth)
        .background(AppTheme.calcSaveGradient)
        .onAppear { sheetWidth = WindowHelpers.windowConstrainedWidth(min: 300, max: 520) }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                if isRenaming {
                    TextField("Name...", text: $renameDraft)
                        .textFieldStyle(.plain)
                        .font(AppTheme.alienLeagueBold(20))
                        .foregroundStyle(AppTheme.background)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(AppTheme.alpha12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .padding(.horizontal, 24)
                        .padding(.top, 46)  // BUG-DEADLINE-2: clear of X button (12pt top + 26pt height + 8pt gap)
                } else {
                    Text(deadline.title)
                        .font(AppTheme.alienLeagueBold(20))
                        .foregroundStyle(AppTheme.background)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                }
                Text(deadlineDateString(deadline.date))
                    .font(AppTheme.alienLeague(13))
                    .foregroundStyle(Color.white.opacity(AppTheme.alpha60))
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(AppTheme.alpha50))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(AppTheme.alpha08))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(Text("Close"))
            .help(String(localized: "Close this panel"))
            .padding(.top, 12)
            .padding(.trailing, 14)
        }
    }

    // MARK: - Rename actions

    @ViewBuilder
    private var renameActions: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("CANCEL") {
                isRenaming = false
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .font(AppTheme.alienLeague(13))
            .foregroundStyle(Color.white.opacity(AppTheme.alpha50))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(AppTheme.alpha08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .help(String(localized: "Cancel and keep the original name"))

            Button("RENAME") {
                let trimmed = renameDraft.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { onRename(deadline, trimmed) }
                isRenaming = false
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .font(AppTheme.alienLeagueBold(13))
            .foregroundStyle(AppTheme.calculateBackground)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .disabled(renameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            .help(String(localized: "Confirm the new name for this deadline"))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
    }

    // MARK: - Normal actions

    @ViewBuilder
    private var normalActions: some View {
        HStack(spacing: 16) {
            Button {
                onLoad(deadline)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 12, weight: .bold))
                    Text("LOAD AS TO")
                        .font(AppTheme.alienLeagueBold(13))
                }
                .foregroundStyle(AppTheme.calculateBackground)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .help(String(localized: "Set the calculator's TO date to this deadline's date"))

            Button {
                isRenaming = true
                renameDraft = deadline.title
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.background.opacity(AppTheme.alpha60))
                    .frame(width: 40, height: 38)
                    .background(Color.white.opacity(AppTheme.alpha12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(Text("Rename deadline"))
            .help(String(localized: "Give this saved deadline a new name"))

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.background.opacity(AppTheme.alpha60))
                    .frame(width: 40, height: 38)
                    .background(Color.white.opacity(AppTheme.alpha12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(Text("Delete deadline"))
            .help(String(localized: "Permanently remove this saved deadline"))
            .alert("Delete \"\(deadline.title)\"?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { onDelete(deadline) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This deadline will be permanently removed.")
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func deadlineDateString(_ date: Date) -> String {
        Formatters.deadlineCompact.string(from: date).uppercased()
    }
}
