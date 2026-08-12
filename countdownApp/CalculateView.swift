//
//  CalculateView.swift
//  countdownApp
//
//  Time-difference calculator — extracted from the original ContentView.
//  From/To dates are edited via the same component stepper used in CountdownDetailView.
//  Result: quantity in alienLeagueBold (38pt), unit in alienLeague (18pt, reduced opacity).
//  Colors: dark brown (AppTheme.dark) background; amber (AppTheme.background) text/icons;
//  transparent elements use Color.white.opacity(X) — not amber-opacity.
//  CALC-SAVE: Named deadline persistence — SAVE button stores the current TO date with a name.
//
//  CALC-SAVE design language (save sheet + detail sheet + list popover):
//  - Background: LinearGradient from purple #593C73 @ 35% opacity (top) → AppTheme.calculateBackground (25% down).
//  - Header: alienLeagueBold title in AppTheme.background (amber); date subtitle in white 55% opacity.
//  - Dividers: Color.white.opacity(0.08), full width minus horizontal padding.
//  - Buttons: amber-fill SAVE/LOAD (dark text), grey CANCEL (white 50% text, white 7% bg), trash (white 10% bg).
//  - Split SAVE button: left = bookmark + "SAVE" (opens save sheet), right = chevron.down (opens list popover).
//    The chevron half uses .contentShape(Rectangle()) so the full padded zone is tappable, not just the icon.
//  - Sheet width: sheetWidth @State + updateSheetWidth() called in both sheet .onAppear — mirrors
//    SnippetEditSheet/NotesSheet pattern; clamps to [300, 520], always 24pt narrower than window.
//

import SwiftUI

struct CalculateView: View {

    @EnvironmentObject private var sunService: SunTimesService

    @AppStorage(AppKeys.calculateFromDate)    private var fromInterval: Double = Date().timeIntervalSince1970
    @AppStorage(AppKeys.calculateToDate)      private var toInterval:   Double = Date().timeIntervalSince1970
    @AppStorage(AppKeys.calculateDisplayMode) private var displayMode: String = "days"

    // Recovery banner
    @State private var corruptedFragments: [String] = []

    // SUN-1-B: hover trigger state for sun popover
    @State private var showSunPopover = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var todaySunTimes: SunTimes? = nil

    // CALC-SAVE: named deadlines
    @State private var namedDeadlines:          [NamedDeadline] = []
    @State private var showSaveSheet:           Bool            = false
    @State private var saveTitleDraft:          String          = ""
    @State private var showDeadlineListPopover: Bool            = false
    @State private var selectedDeadline:        NamedDeadline?  = nil
    @State private var isRenamingDeadline:      Bool            = false
    @State private var renameDraft:             String          = ""
    @State private var showDeleteDeadlineConfirm: Bool          = false
    @State private var popoverWidth:            CGFloat         = 280
    @State private var sheetWidth:              CGFloat         = 400

    private var fromDate: Date {
        get { Date(timeIntervalSince1970: fromInterval) }
        nonmutating set { fromInterval = newValue.timeIntervalSince1970 }
    }
    private var toDate: Date {
        get { Date(timeIntervalSince1970: toInterval) }
        nonmutating set { toInterval = newValue.timeIntervalSince1970 }
    }

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.calculateBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("CALCULATE")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.background)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)

                    Text("FROM")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: Binding(
                        get: { fromDate },
                        set: { fromInterval = snapToMinute($0).timeIntervalSince1970 }
                    ))
                    nowButton(label: "RESET FROM NOW") {
                        fromInterval = snapToMinute(Date()).timeIntervalSince1970
                    }

                    Text("TO")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: Binding(
                        get: { toDate },
                        set: { toInterval = snapToMinute($0).timeIntervalSince1970 }
                    ))
                    nowButton(label: "RESET TO NOW") {
                        toInterval = snapToMinute(Date()).timeIntervalSince1970
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    Text(resultLabel.uppercased())
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))

                    resultRow

                    HStack(spacing: 10) {
                        modeToggle
                        Spacer()
                        saveButton
                    }

                    // Illustration — moon phases in a U-arc
                    GeometryReader { geo in
                        let count = 9
                        let w = geo.size.width
                        let moonSize = (w - CGFloat(count - 1) * 12) / CGFloat(count)
                        let arcDepth: CGFloat = 28
                        HStack(spacing: 12) {
                            ForEach(0..<count, id: \.self) { i in
                                let t = CGFloat(i) / CGFloat(count - 1)
                                let arcOffset = arcDepth * (4 * t * t - 4 * t)
                                Image("pink_moon_\(i + 1)")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: moonSize)
                                    .opacity(0.85)
                                    .offset(y: -arcOffset)
                            }
                        }
                        .onHover { inside in
                            hoverTask?.cancel()
                            if inside {
                                hoverTask = Task {
                                    try? await Task.sleep(for: .milliseconds(200))
                                    guard !Task.isCancelled else { return }
                                    showSunPopover = true
                                }
                            } else {
                                showSunPopover = false
                            }
                        }
                        .popover(isPresented: $showSunPopover) {
                            sunPopoverContent
                        }
                    }
                    .frame(height: 80)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .top) {
            if !corruptedFragments.isEmpty {
                corruptionBanner
            }
        }
        .onAppear {
            loadDeadlines()
            corruptedFragments = (UserDefaults.standard.array(forKey: AppKeys.corruptedDump) as? [String]) ?? []
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DebugNotifications.injectCorruptBanner)) { _ in
            corruptedFragments = (UserDefaults.standard.array(forKey: AppKeys.corruptedDump) as? [String]) ?? []
        }
        #endif
        .sheet(isPresented: $showSaveSheet) { saveSheetContent }
        .sheet(item: $selectedDeadline) { deadline in deadlineDetailContent(deadline) }
    }

    // MARK: - Corruption banner

    private var corruptionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.background)
                .font(.system(size: 14, weight: .semibold))

            Text("\(corruptedFragments.count) item\(corruptedFragments.count == 1 ? "" : "s") could not be loaded")
                .font(AppTheme.alienLeague(13))
                .foregroundStyle(AppTheme.background)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Copy raw data") {
                let json = "[\(corruptedFragments.joined(separator: ",\n"))]"
                if let prettyData = try? JSONSerialization.data(
                    withJSONObject: JSONSerialization.jsonObject(with: Data(json.utf8)),
                    options: [.prettyPrinted, .sortedKeys]
                ), let prettyString = String(data: prettyData, encoding: .utf8) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prettyString, forType: .string)
                } else {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(json, forType: .string)
                }
            }
            .buttonStyle(.plain)
            .focusable(false)
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.calculateBackground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.background.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button("Dismiss") {
                UserDefaults.standard.removeObject(forKey: AppKeys.corruptedDump)
                corruptedFragments = []
            }
            .buttonStyle(.plain)
            .focusable(false)
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.background.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0x8B/255, green: 0x0/255, blue: 0x0/255).opacity(0.75))
    }

    // MARK: - NOW button

    @ViewBuilder
    private func nowButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .bold))
                Text(label)
                    .font(AppTheme.alienLeague(13))
            }
            .foregroundStyle(AppTheme.background)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    // MARK: - Date stepper

    @ViewBuilder
    private func dateStepper(date: Binding<Date>) -> some View {
        HStack(spacing: 10) {
            componentStepper(
                label: "YEAR",
                value: String(cal.component(.year,   from: date.wrappedValue)),
                onInc: { adjustDate(date, .year,   by:  1) },
                onDec: { adjustDate(date, .year,   by: -1) }
            )
            componentStepper(
                label: "MON",
                value: monthAbbrev(from: date.wrappedValue),
                onInc: { adjustDate(date, .month,  by:  1) },
                onDec: { adjustDate(date, .month,  by: -1) }
            )
            componentStepper(
                label: "DAY",
                value: String(format: "%02d", cal.component(.day,    from: date.wrappedValue)),
                onInc: { adjustDate(date, .day,    by:  1) },
                onDec: { adjustDate(date, .day,    by: -1) }
            )
            componentStepper(
                label: "HOUR",
                value: String(format: "%02d", cal.component(.hour,   from: date.wrappedValue)),
                onInc: { adjustDate(date, .hour,   by:  1) },
                onDec: { adjustDate(date, .hour,   by: -1) }
            )
            componentStepper(
                label: "MIN",
                value: String(format: "%02d", cal.component(.minute, from: date.wrappedValue)),
                onInc: { adjustDate(date, .minute, by:  1) },
                onDec: { adjustDate(date, .minute, by: -1) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func componentStepper(
        label: String,
        value: String,
        onInc: @escaping () -> Void,
        onDec: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(Color.white.opacity(0.6))
            LongPressStepperButton(
                systemImage: "chevron.up",
                action: onInc,
                foregroundColor: AppTheme.background,
                backgroundColor: Color.white.opacity(0.12)
            )
            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)
            LongPressStepperButton(
                systemImage: "chevron.down",
                action: onDec,
                foregroundColor: AppTheme.background,
                backgroundColor: Color.white.opacity(0.12)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result display

    @ViewBuilder
    private var resultRow: some View {
        let parts = displayMode == "cal" ? calResultParts : resultParts
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            ForEach(parts.indices, id: \.self) { i in
                Text(parts[i].quantity)
                    .font(AppTheme.alienLeagueBold(38))
                    .foregroundStyle(AppTheme.background)
                    .monospacedDigit()
                Text(parts[i].unit)
                    .font(AppTheme.alienLeague(18))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.trailing, i < parts.count - 1 ? 6 : 0)
            }
        }
        .minimumScaleFactor(0.45)
        .lineLimit(1)
    }

    // MARK: - Mode toggle

    @ViewBuilder
    private var modeToggle: some View {
        Button {
            displayMode = displayMode == "days" ? "cal" : "days"
        } label: {
            Text(displayMode == "days" ? "CAL" : "DAYS")
                .font(AppTheme.alienLeague(13))
                .foregroundStyle(AppTheme.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    // MARK: - CALC-SAVE: Save / Edit split button
    // Left segment: opens save sheet. Right segment (▾): click-triggered popover with deadline list.
    // The chevron uses .contentShape(Rectangle()) so the full padded zone is tappable, not just the icon.

    @ViewBuilder
    private var saveButton: some View {
        HStack(spacing: 0) {
            Button {
                saveTitleDraft = ""
                showSaveSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("SAVE")
                        .font(AppTheme.alienLeague(13))
                }
                .foregroundStyle(AppTheme.background)
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .focusable(false)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 20)

            Button {
                if !namedDeadlines.isEmpty {
                    showDeadlineListPopover.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(
                        namedDeadlines.isEmpty
                            ? AppTheme.background.opacity(0.3)
                            : AppTheme.background
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())   // FIX: full padded area tappable, not just the icon
            }
            .buttonStyle(.plain)
            .focusable(false)
            .popover(isPresented: $showDeadlineListPopover) {
                deadlineListPopoverContent
            }
        }
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - CALC-SAVE: Shared gradient background helper
    // Purple #593C73 @ 35% opacity fades into calculateBackground by 25% of the view height.
    // Used by the list popover, save sheet, and detail sheet for visual consistency.

    private var calcSaveGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35), location: 0),
                .init(color: AppTheme.calculateBackground, location: 0.25),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - CALC-SAVE: Deadline list popover

    @ViewBuilder
    private var deadlineListPopoverContent: some View {
        VStack(spacing: 0) {
            Text("SAVED DEADLINES")
                .font(AppTheme.alienLeague(11))
                .foregroundStyle(Color.white.opacity(0.5))
                .kerning(2)
                .padding(.top, 18)
                .padding(.bottom, 12)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(namedDeadlines) { deadline in
                    Button {
                        showDeadlineListPopover = false
                        DispatchQueue.main.async { selectedDeadline = deadline }
                    } label: {
                        HStack(alignment: .center, spacing: 6) {
                            Text(deadline.title)
                                .font(AppTheme.alienLeague(12))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .lineLimit(1)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(deadlineRemainingString(for: deadline.date))
                                    .font(AppTheme.alienLeagueBold(15))
                                    .foregroundStyle(
                                        deadline.date > Date()
                                            ? AppTheme.background
                                            : Color.white.opacity(0.35)
                                    )
                                Text(deadlineDateString(deadline.date))
                                    .font(AppTheme.alienLeague(11))
                                    .foregroundStyle(Color.white.opacity(0.35))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)

                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: popoverWidth)
        .background(calcSaveGradient)
        .onAppear {
            let windowWidth = NSApp.mainWindow?.frame.width
                ?? NSApp.windows.first(where: { $0.isVisible })?.frame.width
                ?? 600
            popoverWidth = min(320, max(220, windowWidth - 48))
        }
    }

    // MARK: - CALC-SAVE: Save sheet (new deadline name entry)
    // Design matches the list popover: purple gradient header, white 8% divider, amber SAVE button.

    @ViewBuilder
    private var saveSheetContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — purple gradient zone
            VStack(spacing: 8) {
                Text("SAVE DEADLINE")
                    .font(AppTheme.alienLeagueBold(18))
                    .foregroundStyle(AppTheme.background)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 28)

                Text(deadlineDateString(snapToMinute(toDate)))
                    .font(AppTheme.alienLeague(13))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // Body — name field + action buttons
            VStack(spacing: 16) {
                TextField("Name...", text: $saveTitleDraft)
                    .textFieldStyle(.plain)
                    .font(AppTheme.alienLeague(15))
                    .foregroundStyle(AppTheme.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    Spacer()
                    Button("CANCEL") {
                        showSaveSheet = false
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .font(AppTheme.alienLeague(13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("SAVE") {
                        let trimmed = saveTitleDraft.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { addNamedDeadline(title: trimmed) }
                        showSaveSheet = false
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .font(AppTheme.alienLeagueBold(13))
                    .foregroundStyle(AppTheme.calculateBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(saveTitleDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth)
        .background(calcSaveGradient)
        .onAppear { updateSheetWidth() }
    }

    // MARK: - CALC-SAVE: Deadline detail sheet (load / rename / delete)
    // Same design language as save sheet and list popover.
    // Rename mode: pencil button switches the title header into an editable TextField;
    // CANCEL reverts, RENAME saves and persists.

    @ViewBuilder
    private func deadlineDetailContent(_ deadline: NamedDeadline) -> some View {
        VStack(spacing: 0) {
            // Header — title (static or editable) + date, with X dismiss overlay
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    if isRenamingDeadline {
                        TextField("Name...", text: $renameDraft)
                            .textFieldStyle(.plain)
                            .font(AppTheme.alienLeagueBold(20))
                            .foregroundStyle(AppTheme.background)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 24)
                            .padding(.top, 46)  // BUG-DEADLINE-2: clear X button (12pt top + 26pt height + 8pt gap)
                    } else {
                        Text(deadline.title)
                            .font(AppTheme.alienLeagueBold(20))
                            .foregroundStyle(AppTheme.background)
                            .multilineTextAlignment(.center)
                            .padding(.top, 28)
                    }
                    Text(deadlineDateString(deadline.date))
                        .font(AppTheme.alienLeague(13))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)

                Button { selectedDeadline = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.top, 12)
                .padding(.trailing, 14)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 28)

            // Body — actions (normal mode) or rename confirm (rename mode)
            if isRenamingDeadline {
                HStack(spacing: 12) {
                    Spacer()
                    Button("CANCEL") {
                        isRenamingDeadline = false
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .font(AppTheme.alienLeague(13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("RENAME") {
                        let trimmed = renameDraft.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty,
                           let idx = namedDeadlines.firstIndex(where: { $0.id == deadline.id }) {
                            namedDeadlines[idx].title = trimmed
                            saveDeadlines()
                        }
                        isRenamingDeadline = false
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .font(AppTheme.alienLeagueBold(13))
                    .foregroundStyle(AppTheme.calculateBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(renameDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            } else {
                HStack(spacing: 16) {
                    Button {
                        toInterval = deadline.date.timeIntervalSince1970
                        selectedDeadline = nil
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)

                    Button {
                        isRenamingDeadline = true
                        renameDraft = deadline.title
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.background.opacity(0.6))
                            .frame(width: 40, height: 38)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)

                    Button {
                        showDeleteDeadlineConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.background.opacity(0.6))
                            .frame(width: 40, height: 38)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .alert("Delete \"\(deadline.title)\"?", isPresented: $showDeleteDeadlineConfirm) {
                        Button("Delete", role: .destructive) {
                            namedDeadlines.removeAll { $0.id == deadline.id }
                            saveDeadlines()
                            selectedDeadline = nil
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This deadline will be permanently removed.")
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth)
        .background(calcSaveGradient)
        .onAppear { updateSheetWidth() }
        .onDisappear { isRenamingDeadline = false }
    }

    // MARK: - CALC-SAVE: Sheet width helper
    // Mirrors SnippetEditSheet / NotesSheet pattern: reads real window width on appear,
    // clamps to [300, 520], subtracts windowMargin so the sheet never overflows the window.

    private func updateSheetWidth() {
        let windowMargin: CGFloat = 24
        let windowWidth = NSApp.mainWindow?.frame.width
            ?? NSApp.windows.first(where: { $0.isVisible })?.frame.width
            ?? 600
        sheetWidth = max(300, min(520, windowWidth - windowMargin))
    }

    // MARK: - CALC-SAVE: Persistence

    private func loadDeadlines() {
        guard let data = UserDefaults.standard.data(forKey: AppKeys.namedDeadlines) else { return }

        // Per-item recovery: parse as a raw JSON array so one corrupt deadline
        // does not wipe the entire list. Failed items are captured as raw JSON
        // strings and accumulated in AppKeys.corruptedDump.
        guard let rawArray = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else { return }

        var deadlines: [NamedDeadline] = []
        var corruptFragments: [String] = []

        for element in rawArray {
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { continue }
            do {
                deadlines.append(try JSONDecoder().decode(NamedDeadline.self, from: elementData))
            } catch {
                if let fragment = String(data: elementData, encoding: .utf8) {
                    corruptFragments.append(fragment)
                }
            }
        }

        AppKeys.appendCorruptFragments(corruptFragments)
        namedDeadlines = deadlines
    }

    private func saveDeadlines() {
        if let data = try? JSONEncoder().encode(namedDeadlines) {
            UserDefaults.standard.set(data, forKey: AppKeys.namedDeadlines)
        }
    }

    private func addNamedDeadline(title: String) {
        let nd = NamedDeadline(title: title, date: snapToMinute(toDate))
        namedDeadlines.insert(nd, at: 0)   // newest first
        saveDeadlines()
    }

    // MARK: - Computed

    private var isFuture:    Bool         { toDate > fromDate }
    private var difference:  TimeInterval { abs(toDate.timeIntervalSince(fromDate)) }
    private var resultLabel: String       { isFuture ? "Remaining time:" : "Elapsed time:" }

    private struct TimePart { let quantity: String; let unit: String }

    private var calResultParts: [TimePart] {
        let (earlier, later) = fromDate <= toDate ? (fromDate, toDate) : (toDate, fromDate)
        let comps = cal.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: earlier, to: later
        )
        let all: [(Int, String)] = [
            (comps.year   ?? 0, "y"),
            (comps.month  ?? 0, "mo"),
            (comps.day    ?? 0, "d"),
            (comps.hour   ?? 0, "h"),
            (comps.minute ?? 0, "m"),
            (comps.second ?? 0, "s"),
        ]
        let firstNonZero = all.firstIndex(where: { $0.0 != 0 }) ?? (all.count - 1)
        return Array(all[firstNonZero...]).map { TimePart(quantity: "\($0.0)", unit: $0.1) }
    }

    private var resultParts: [TimePart] {
        let total   = Int(difference)
        let days    = total / 86400
        let hours   = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return [
            TimePart(quantity: "\(days)",    unit: "d"),
            TimePart(quantity: "\(hours)",   unit: "h"),
            TimePart(quantity: "\(minutes)", unit: "m"),
            TimePart(quantity: "\(seconds)", unit: "s"),
        ]
    }

    // MARK: - Sun popover (SUN-1-C)

    @ViewBuilder
    private var sunPopoverContent: some View {
        SunPanel(sunTimes: todaySunTimes, isLoading: sunService.isLoading)
            .onAppear { fetchTodaySunTimes() }
    }

    private func fetchTodaySunTimes() {
        guard todaySunTimes == nil else { return }
        Task {
            todaySunTimes = await sunService.sunTimes(for: Date())
        }
    }

    // MARK: - Helpers

    private func adjustDate(_ binding: Binding<Date>, _ c: Calendar.Component, by value: Int) {
        if let d = cal.date(byAdding: c, value: value, to: binding.wrappedValue) {
            binding.wrappedValue = snapToMinute(d)
        }
    }

    private func snapToMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60)
    }

    private func monthAbbrev(from date: Date) -> String {
        Formatters.monthAbbrev.string(from: date).uppercased()
    }

    private func deadlineDateString(_ date: Date) -> String {
        Formatters.deadlineCompact.string(from: date).uppercased()
    }

    /// Compact remaining-time string for the saved-deadlines list.
    /// Shows the two most significant non-zero components (e.g. "42D 3H", "2Y 5MO", "14M").
    /// Returns "EXPIRED" for dates in the past.
    private func deadlineRemainingString(for date: Date) -> String {
        let now = Date()
        guard date > now else { return "EXPIRED" }
        let comps = cal.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: now, to: date
        )
        let pairs: [(Int, String)] = [
            (comps.year  ?? 0, "Y"),
            (comps.month ?? 0, "MO"),
            (comps.day   ?? 0, "D"),
            (comps.hour  ?? 0, "H"),
            (comps.minute ?? 0, "M"),
        ]
        let nonZero = pairs.filter { $0.0 > 0 }
        let top = nonZero.prefix(2)
        guard !top.isEmpty else { return "< 1M" }
        return top.map { "\($0.0)\($0.1)" }.joined(separator: " ")
    }
}

#Preview { CalculateView().environmentObject(SunTimesService()) }
