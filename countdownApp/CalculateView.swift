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

import SwiftUI

struct CalculateView: View {

    @EnvironmentObject private var sunService: SunTimesService

    @AppStorage("calculateFromDate")    private var fromInterval: Double = Date().timeIntervalSince1970
    @AppStorage("calculateToDate")      private var toInterval:   Double = Date().timeIntervalSince1970
    @AppStorage("calculateDisplayMode") private var displayMode: String = "days"

    // SUN-1-B: hover trigger state for sun popover
    @State private var showSunPopover = false
    @State private var hoverTask: DispatchWorkItem?
    @State private var todaySunTimes: SunTimes? = nil

    // CALC-SAVE: named deadlines
    @State private var namedDeadlines:          [NamedDeadline] = []
    @State private var showSaveSheet:           Bool            = false
    @State private var saveTitleDraft:          String          = ""
    @State private var showDeadlineListPopover: Bool            = false
    @State private var saveHoverTask:           DispatchWorkItem?
    @State private var selectedDeadline:        NamedDeadline?  = nil

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
                                let task = DispatchWorkItem { showSunPopover = true }
                                hoverTask = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
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
        .onAppear { loadDeadlines() }
        .sheet(isPresented: $showSaveSheet) { saveSheetContent }
        .sheet(item: $selectedDeadline) { deadline in deadlineDetailContent(deadline) }
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

    // MARK: - CALC-SAVE: Save button (click = new save sheet, hover = list popover)

    @ViewBuilder
    private var saveButton: some View {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { inside in
            saveHoverTask?.cancel()
            if inside && !namedDeadlines.isEmpty {
                let task = DispatchWorkItem { showDeadlineListPopover = true }
                saveHoverTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
            } else {
                showDeadlineListPopover = false
            }
        }
        .popover(isPresented: $showDeadlineListPopover) {
            deadlineListPopoverContent
        }
    }

    // MARK: - CALC-SAVE: Deadline list popover

    @ViewBuilder
    private var deadlineListPopoverContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SAVED DEADLINES")
                .font(AppTheme.alienLeague(11))
                .foregroundStyle(Color.white.opacity(0.5))
                .kerning(2)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(namedDeadlines) { deadline in
                        Button {
                            showDeadlineListPopover = false
                            DispatchQueue.main.async {
                                selectedDeadline = deadline
                            }
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(deadline.title)
                                        .font(AppTheme.alienLeagueBold(13))
                                        .foregroundStyle(AppTheme.background)
                                        .lineLimit(1)
                                    Text(deadlineDateString(deadline.date))
                                        .font(AppTheme.alienLeague(11))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)

                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 1)
                    }
                }
            }
            .frame(maxHeight: 260)
        }
        .frame(minWidth: 270)
        .background(AppTheme.calculateBackground)
    }

    // MARK: - CALC-SAVE: Save sheet (new deadline name entry)

    @ViewBuilder
    private var saveSheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SAVE DEADLINE")
                .font(AppTheme.alienLeagueBold(18))
                .foregroundStyle(AppTheme.background)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(deadlineDateString(snapToMinute(toDate)))
                .font(AppTheme.alienLeague(14))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .center)

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
        .padding(28)
        .frame(minWidth: 320)
        .background(AppTheme.calculateBackground)
    }

    // MARK: - CALC-SAVE: Deadline detail sheet (load / delete)

    @ViewBuilder
    private func deadlineDetailContent(_ deadline: NamedDeadline) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(deadline.title)
                    .font(AppTheme.alienLeagueBold(20))
                    .foregroundStyle(AppTheme.background)
                    .multilineTextAlignment(.center)

                Text(deadlineDateString(deadline.date))
                    .font(AppTheme.alienLeague(14))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 28)

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
                    namedDeadlines.removeAll { $0.id == deadline.id }
                    saveDeadlines()
                    selectedDeadline = nil
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
            }
            .padding(.vertical, 24)
        }
        .frame(minWidth: 300)
        .background(AppTheme.calculateBackground)
    }

    // MARK: - CALC-SAVE: Persistence

    private func loadDeadlines() {
        guard let data    = UserDefaults.standard.data(forKey: "namedDeadlines"),
              let decoded = try? JSONDecoder().decode([NamedDeadline].self, from: data)
        else { return }
        namedDeadlines = decoded
    }

    private func saveDeadlines() {
        if let data = try? JSONEncoder().encode(namedDeadlines) {
            UserDefaults.standard.set(data, forKey: "namedDeadlines")
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
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date).uppercased()
    }

    private func deadlineDateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy MMM dd  HH:mm"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date).uppercased()
    }
}

#Preview { CalculateView().environmentObject(SunTimesService()) }
