//
//  AnalyticsView.swift
//  Pango
//

import SwiftUI
import Charts

enum ChartStyle: String, CaseIterable, Identifiable {
    case bar = "BAR"
    case line = "LINE"
    var id: String { rawValue }
}

enum ChartMetric: String, CaseIterable, Identifiable {
    case requests = "REQUESTS"
    case bandwidth = "BANDWIDTH"
    var id: String { rawValue }
}

struct AnalyticsView: View {

    var resourceId: Int?
    var resourceName: String?
    var sites: [Site] = []

    @State private var data: AnalyticsData?
    @State private var recentLogs: [RequestAuditLog] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""

    @State private var dateRange: DateRange = .week
    @State private var customStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customEnd: Date = Date()
    @State private var chartStyle: ChartStyle = .bar
    @State private var chartMetric: ChartMetric = .requests
    @State private var selectedDay: DailyRequests?

    private var startDate: Date {
        switch dateRange {
        case .day:   return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .week:  return Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        case .custom: return customStart
        }
    }

    private var endDate: Date {
        dateRange == .custom ? customEnd : Date()
    }

    private var xAxisFormat: Date.FormatStyle {
        .dateTime.month(.defaultDigits).day()
    }

    var chartAccessibilityLabel: String {
        guard let data = data else { return "" }
        return "\(data.totalRequests) requests, \(data.totalBlocked) blocked"
    }

    private var trendInfo: (symbol: String, percentage: Double, isUp: Bool)? {
        guard let days = data?.requestsPerDay, days.count >= 2 else { return nil }
        let mid = days.count / 2
        let firstHalf = Double(days[..<mid].reduce(0) { $0 + $1.totalCount })
        let secondHalf = Double(days[mid...].reduce(0) { $0 + $1.totalCount })
        guard firstHalf > 0 else { return nil }
        let pct = ((secondHalf - firstHalf) / firstHalf) * 100
        let isUp = pct >= 0
        return (isUp ? "arrow.up.right" : "arrow.down.right", abs(pct), isUp)
    }

    private var showBandwidthOption: Bool {
        resourceId == nil && !sites.isEmpty
    }

    var body: some View {
        List {
            dateRangeSection

            if let data = data {
                summarySection(data)
                chartSection(data)
                peakInsightSection(data)
                if !data.requestsPerCountry.isEmpty {
                    countriesSection(data)
                }
            }

            if !recentLogs.isEmpty {
                recentLogsSection
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if isLoading && data == nil {
                ProgressView()
            } else if !errorMessage.isEmpty && data == nil {
                ContentUnavailableView("ERROR", systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage))
            } else if !isLoading && data == nil {
                ContentUnavailableView("NO_ANALYTICS", systemImage: "chart.bar.xaxis",
                    description: Text("NO_ANALYTICS_DESCRIPTION"))
            }
        }
        .navigationTitle(resourceName ?? String(localized: "ANALYTICS"))
        .task {
            await fetchAll()
        }
        .refreshable {
            await fetchAll()
        }
        .onChange(of: dateRange) {
            Task { await fetchAll() }
        }
        .onChange(of: customStart) {
            if dateRange == .custom { Task { await fetchAll() } }
        }
        .onChange(of: customEnd) {
            if dateRange == .custom { Task { await fetchAll() } }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section {
            Picker("DATE_RANGE", selection: $dateRange) {
                ForEach(DateRange.allCases) { range in
                    Text(range == .custom ? String(localized: "CUSTOM") : range.rawValue)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if dateRange == .custom {
                DatePicker("FROM", selection: $customStart, in: ...customEnd, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                DatePicker("TO", selection: $customEnd, in: customStart..., displayedComponents: [.date])
                    .datePickerStyle(.compact)
            }
        }
    }

    // MARK: - Summary Section

    @ViewBuilder
    private func summarySection(_ data: AnalyticsData) -> some View {
        Section {
            // Total Requests
            summaryRow(
                label: String(localized: "TOTAL_REQUESTS"),
                value: data.totalRequests,
                maxValue: data.totalRequests,
                barColor: Color.secondary.opacity(0.15)
            ) {
                if let trend = trendInfo {
                    Image(systemName: trend.symbol)
                        .foregroundStyle(trend.isUp ? Color.green : Color.red)
                        .font(.caption)
                    Text(String(format: "%.0f%%", trend.percentage))
                        .foregroundStyle(trend.isUp ? Color.green : Color.red)
                        .font(.caption)
                }
            }

            // Allowed
            summaryRow(
                label: String(localized: "ALLOWED"),
                value: data.totalAllowed,
                maxValue: data.totalRequests,
                barColor: Color(.systemGreen).opacity(0.15)
            )

            // Blocked
            summaryRow(
                label: String(localized: "BLOCKED"),
                value: data.totalBlocked,
                maxValue: data.totalRequests,
                barColor: Color(.systemRed).opacity(0.15)
            ) {
                Text(String(format: "%.1f%%", data.blockRate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func summaryRow(
        label: String,
        value: Int,
        maxValue: Int,
        barColor: Color,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            trailing()
            Text(humanNumber(value))
                .fontWeight(.semibold)
                .font(.body.monospacedDigit())
        }
        .background(alignment: .leading) {
            GeometryReader { geo in
                let fraction = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * fraction, height: geo.size.height)
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(_ data: AnalyticsData) -> some View {
        Section {
            // Compact toolbar row for chart controls
            HStack {
                if showBandwidthOption {
                    Picker("", selection: $chartMetric) {
                        ForEach(ChartMetric.allCases) { metric in
                            Text(LocalizedStringKey(metric.rawValue)).tag(metric)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                Spacer()

                if chartMetric == .requests {
                    Picker("", selection: $chartStyle) {
                        ForEach(ChartStyle.allCases) { style in
                            Text(LocalizedStringKey(style.rawValue)).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            if chartMetric == .requests {
                requestsChart(data)
            } else {
                bandwidthSummary
                bandwidthChart
            }
        } header: {
            Text(chartMetric == .requests ? "REQUESTS_OVER_TIME" : "NETWORK_USAGE")
        }
        .textCase(nil)
    }

    private func chartSelectionGesture(proxy: ChartProxy, geo: GeometryProxy, data: AnalyticsData) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let origin = geo[proxy.plotFrame!].origin
                let location = CGPoint(
                    x: value.location.x - origin.x,
                    y: value.location.y - origin.y
                )
                let nearest = findNearestDay(at: location, proxy: proxy, data: data)
                if nearest?.id != selectedDay?.id {
                    hapticLight()
                }
                selectedDay = nearest
            }
            .onEnded { _ in
                selectedDay = nil
            }
    }

    private func findNearestDay(at location: CGPoint, proxy: ChartProxy, data: AnalyticsData) -> DailyRequests? {
        guard let date: Date = proxy.value(atX: location.x) else { return nil }
        return data.requestsPerDay.min(by: {
            guard let a = $0.parsedDate, let b = $1.parsedDate else { return false }
            return abs(a.timeIntervalSince(date)) < abs(b.timeIntervalSince(date))
        })
    }

    @ChartContentBuilder
    private var selectedDayRuleMark: some ChartContent {
        if let day = selectedDay, let date = day.parsedDate {
            RuleMark(x: .value("Selected", date, unit: .day))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
        }
    }

    @ViewBuilder
    private var selectedDayTooltip: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(selectedDay?.shortDay ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(humanNumber(selectedDay?.allowedCount ?? 0))
                        .foregroundStyle(.primary)
                }
                HStack(spacing: 3) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(humanNumber(selectedDay?.blockedCount ?? 0))
                        .foregroundStyle(.primary)
                }
            }
            .font(.caption.weight(.medium).monospacedDigit())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .opacity(selectedDay != nil ? 1 : 0)
    }

    @ViewBuilder
    private func requestsChart(_ data: AnalyticsData) -> some View {
        if !data.requestsPerDay.isEmpty {
            let allowedLabel = String(localized: "ALLOWED")
            let blockedLabel = String(localized: "BLOCKED")

            if chartStyle == .bar {
                Chart {
                    ForEach(data.requestsPerDay) { day in
                        if let date = day.parsedDate {
                            BarMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Count", day.allowedCount)
                            )
                            .foregroundStyle(by: .value("Type", allowedLabel))
                        }
                    }
                    ForEach(data.requestsPerDay) { day in
                        if let date = day.parsedDate {
                            BarMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Count", day.blockedCount)
                            )
                            .foregroundStyle(by: .value("Type", blockedLabel))
                        }
                    }
                    selectedDayRuleMark
                }
                .chartForegroundStyleScale([
                    allowedLabel: Color(.systemGreen),
                    blockedLabel: Color(.systemRed)
                ])
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: xAxisFormat)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(chartSelectionGesture(proxy: proxy, geo: geo, data: data))
                    }
                }
                .chartLegend(position: .bottom, spacing: 4)
                .frame(height: 200)
                .overlay(alignment: .top) { selectedDayTooltip.padding(.top, 4) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chartAccessibilityLabel)
            } else {
                Chart {
                    ForEach(data.requestsPerDay) { day in
                        if let date = day.parsedDate {
                            LineMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Count", day.allowedCount),
                                series: .value("Type", "Allowed")
                            )
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    ForEach(data.requestsPerDay) { day in
                        if let date = day.parsedDate {
                            LineMark(
                                x: .value("Day", date, unit: .day),
                                y: .value("Count", day.blockedCount),
                                series: .value("Type", "Blocked")
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    selectedDayRuleMark
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: xAxisFormat)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(chartSelectionGesture(proxy: proxy, geo: geo, data: data))
                    }
                }
                .frame(height: 200)
                .overlay(alignment: .top) { selectedDayTooltip.padding(.top, 4) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chartAccessibilityLabel)
            }
        }
    }

    // MARK: - Bandwidth

    @ViewBuilder
    private var bandwidthSummary: some View {
        let totalIn = sites.reduce(0.0) { $0 + Double($1.megabytesIn ?? 0) }
        let totalOut = sites.reduce(0.0) { $0 + Double($1.megabytesOut ?? 0) }

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DOWNLOAD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(humanMegabyte(from: Float(totalIn)))
                    .fontWeight(.semibold)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color(.systemGreen))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("UPLOAD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(humanMegabyte(from: Float(totalOut)))
                    .fontWeight(.semibold)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color(.systemRed))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL_BANDWIDTH")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(humanMegabyte(from: Float(totalIn + totalOut)))
                    .fontWeight(.semibold)
                    .font(.body.monospacedDigit())
            }
        }
    }

    private var sortedBandwidthSites: [Site] {
        sites
            .filter { ($0.megabytesIn ?? 0) + ($0.megabytesOut ?? 0) > 0 }
            .sorted { a, b in
                let aTotal = (a.megabytesIn ?? 0) + (a.megabytesOut ?? 0)
                let bTotal = (b.megabytesIn ?? 0) + (b.megabytesOut ?? 0)
                return aTotal > bTotal
            }
    }

    @ViewBuilder
    private var bandwidthChart: some View {
        let filtered = sortedBandwidthSites
        let downloadLabel = String(localized: "DOWNLOAD")
        let uploadLabel = String(localized: "UPLOAD")

        Chart(filtered, id: \.siteId) { site in
            let mbIn: Float = site.megabytesIn ?? 0
            let mbOut: Float = site.megabytesOut ?? 0

            BarMark(
                x: .value("MB", mbIn),
                y: .value("Site", site.name)
            )
            .foregroundStyle(by: .value("Direction", downloadLabel))
            .cornerRadius(3)

            BarMark(
                x: .value("MB", mbOut),
                y: .value("Site", site.name)
            )
            .foregroundStyle(by: .value("Direction", uploadLabel))
            .cornerRadius(3)
        }
        .chartForegroundStyleScale([
            downloadLabel: Color(.systemGreen),
            uploadLabel: Color(.systemRed)
        ])
        .chartXAxisLabel("MB")
        .frame(height: max(CGFloat(filtered.count) * 44, 120))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("NETWORK_USAGE")
    }

    // MARK: - Peak Insight

    @ViewBuilder
    private func peakInsightSection(_ data: AnalyticsData) -> some View {
        if chartMetric == .requests, let peak = data.peakDay, peak.totalCount > 0 {
            Section {
                HStack {
                    Image(systemName: "flame")
                        .foregroundStyle(.orange)
                    Text("BUSIEST_DAY")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(peak.peakLabel) — \(humanNumber(peak.totalCount))")
                        .fontWeight(.medium)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Countries Section

    @ViewBuilder
    private func countriesSection(_ data: AnalyticsData) -> some View {
        let maxCount = data.requestsPerCountry.first?.count ?? 1

        Section(header: Text("TOP_COUNTRIES")) {
            ForEach(data.requestsPerCountry.prefix(10)) { country in
                HStack {
                    Text(countryFlag(country.code))
                    Text(countryName(country.code))
                    Spacer()
                    Text(humanNumber(country.count))
                        .foregroundStyle(.secondary)
                        .font(.subheadline.monospacedDigit())
                }
                .background(alignment: .leading) {
                    GeometryReader { geo in
                        let fraction = maxCount > 0 ? CGFloat(country.count) / CGFloat(maxCount) : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.08))
                            .frame(width: geo.size.width * fraction, height: geo.size.height)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .textCase(nil)
    }

    // MARK: - Recent Logs

    @ViewBuilder
    private var recentLogsSection: some View {
        Section {
            ForEach(recentLogs) { log in
                NavigationLink {
                    LogDetailView(log: log)
                } label: {
                    LogRowView(log: log)
                }
            }
            NavigationLink {
                LogsView()
            } label: {
                Text("VIEW_ALL")
                    .foregroundStyle(.tint)
            }
        } header: {
            Text("RECENT_ACTIVITY")
        }
        .textCase(nil)
    }

    // MARK: - Fetch

    private func fetchAll() async {
        if data == nil { isLoading = true }
        errorMessage = ""

        async let analyticsTask: () = fetchAnalytics()
        async let logsTask: () = fetchRecentLogs()
        _ = await (analyticsTask, logsTask)

        isLoading = false
    }

    private func fetchAnalytics() async {
        do {
            data = try await AnalyticsRequest.fetchAnalytics(
                resourceId: resourceId,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchRecentLogs() async {
        do {
            let logs = try await LogsRequest.fetchRequestLogs(limit: 5)
            if let resourceId = resourceId {
                recentLogs = logs.filter { $0.resourceId == resourceId }
            } else {
                recentLogs = logs
            }
        } catch {
            // Silently fail — logs are supplementary
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
