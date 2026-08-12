//
//  SunPanel.swift
//  countdownApp
//
//  Popover content for daily sun/moon timing data (SUN-1-C).
//  Receives todaySunTimes: SunTimes? and isLoading: Bool from CalculateView.
//  Layout:
//    [sun.svg icon]
//    [MORNING | EVENING]
//    [DAY     | MOON   ]
//    [GOLDEN / BLUE HOUR]
//

import SwiftUI

struct SunPanel: View {

    let sunTimes: SunTimes?
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 0) {
            sunIcon
            if let st = sunTimes {
                dataContent(st)
            } else if isLoading {
                loadingState
            } else {
                noDataState
            }
        }
        .padding(.vertical, 20)
        .frame(minWidth: 360)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35), location: 0),
                    .init(color: AppTheme.calculateBackground, location: 0.25),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Sun icon

    private var sunIcon: some View {
        Image("sun")
            .resizable()
            .scaledToFit()
            .frame(height: 100)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    // MARK: - Data content

    @ViewBuilder
    private func dataContent(_ st: SunTimes) -> some View {
        HStack(alignment: .top, spacing: 0) {
            morningSection(st)
            sectionDivider
            eveningSection(st)
        }
        .padding(.top, 8)

        fullDivider
            .padding(.vertical, 10)

        HStack(alignment: .top, spacing: 0) {
            daySection(st)
            sectionDivider
            moonSection(st)
        }

        fullDivider
            .padding(.vertical, 10)

        goldenBlueSection(st)
            .padding(.horizontal, 20)
    }

    // MARK: - Morning

    private func morningSection(_ st: SunTimes) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("☀️  MORNING")
            timeRow(label: "First light", date: st.firstLight)
            timeRow(label: "Dawn",        date: st.dawn)
            timeRow(label: "Sunrise",     date: st.sunrise)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Evening

    private func eveningSection(_ st: SunTimes) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("🌆  EVENING")
            timeRow(label: "Sunset",     date: st.sunset)
            timeRow(label: "Dusk",       date: st.dusk)
            timeRow(label: "Last light", date: st.lastLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Day

    private func daySection(_ st: SunTimes) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("⚖️  DAY")
            timeRow(label: "Solar noon", date: st.solarNoon)
            labelRow(label: "Day length", value: dayLengthString(st.dayLength))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Moon

    private func moonSection(_ st: SunTimes) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("🌙  MOON")
            if let mr = st.moonrise {
                timeRow(label: "Moonrise", date: mr)
            } else {
                labelRow(label: "Moonrise", value: "—")
            }
            if let ms = st.moonset {
                timeRow(label: "Moonset", date: ms)
            } else {
                labelRow(label: "Moonset", value: "—")
            }
            labelRow(label: "Phase", value: st.moonPhase)
            labelRow(
                label: "Illumination",
                value: String(format: "%.0f%%", st.moonIllumination)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Golden / Blue hour

    private func goldenBlueSection(_ st: SunTimes) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("📷  GOLDEN / BLUE HOUR")
            windowRow(label: "Morning golden", window: st.goldenHourMorning)
            windowRow(label: "Morning blue",   window: st.blueHourMorning)
            windowRow(label: "Evening golden", window: st.goldenHourEvening)
            windowRow(label: "Evening blue",   window: st.blueHourEvening)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading / no data states

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(AppTheme.background)
            Text("LOADING")
                .font(AppTheme.alienLeague(12))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    private var noDataState: some View {
        VStack(spacing: 8) {
            Text("NO DATA")
                .font(AppTheme.alienLeagueBold(16))
                .foregroundStyle(AppTheme.background)
            Text("Sun times unavailable")
                .font(AppTheme.alienLeague(12))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Row helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.alienLeague(11))
            .foregroundStyle(Color.white.opacity(0.5))
            .padding(.bottom, 2)
    }

    /// Label + HH:mm time value, value in amber
    private func timeRow(label: String, date: Date) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(AppTheme.alienLeague(12))
                .foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text(timeString(date))
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
        }
    }

    /// Label + arbitrary string value, value in amber
    private func labelRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(AppTheme.alienLeague(12))
                .foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(AppTheme.alienLeagueBold(13))
                .foregroundStyle(AppTheme.background)
                .multilineTextAlignment(.trailing)
        }
    }

    /// HH:mm–HH:mm window row
    private func windowRow(label: String, window: TimeWindow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(AppTheme.alienLeague(12))
                .foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text("\(timeString(window.begin))–\(timeString(window.end))")
                .font(AppTheme.alienLeagueBold(13))
                .foregroundStyle(AppTheme.background)
        }
    }

    // MARK: - Dividers

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1)
    }

    private var fullDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: - Formatters

    private func timeString(_ date: Date) -> String {
        Formatters.time.string(from: date)
    }

    private func dayLengthString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return "\(h)h \(m)m"
    }
}
