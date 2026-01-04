//
//  ContentView.swift
//  Clack Tracker
//
//  Created by Alexandru Tirim on 28.12.2025.
//

import SwiftUI

struct ContentView: View {
    // Get the monitor instance passed from the app
    @EnvironmentObject var monitor: KeystrokeMonitor

    @Environment(\.colorScheme) var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Clack Tracker")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Today's count (big and prominent)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("TODAY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        if let trend = monitor.trendPercentage {
                            Text(trendText(trend))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(trend >= 0 ? .green : .orange)
                        }
                    }
                    Text("\(formatNumber(monitor.todayCount))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 4)

                // Statistics - only show if there's data
                if monitor.totalAllTime > 0 || !monitor.history.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STATISTICS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .tracking(0.5)

                        VStack(spacing: 8) {
                            if !monitor.history.isEmpty {
                                StatRow(
                                    label: "Average",
                                    value: formatNumber(monitor.averageCount),
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                            }

                            if let peak = monitor.peakDay, peak.count > 0 {
                                StatRow(
                                    label: "Peak Day",
                                    value: "\(formatNumber(peak.count)) · \(formatDate(peak.date))",
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                            }

                            if monitor.totalAllTime > 0 {
                                StatRow(
                                    label: "All Time",
                                    value: formatNumber(monitor.totalAllTime),
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                            }
                        }
                    }
                }

                // Last 7 days - only show days with data
                let daysWithData = monitor.last7Days.filter { $0.count > 0 }
                if !daysWithData.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HISTORY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                            .tracking(0.5)

                        VStack(spacing: 6) {
                            ForEach(daysWithData, id: \.date) { day in
                                HStack {
                                    Text(formatDate(day.date))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(formatNumber(day.count))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.gray)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if daysAgo <= 6 {
            return "\(daysAgo) days ago"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            let millions = Double(number) / 1_000_000
            return String(format: "%.1fM", millions)
        } else if number >= 10_000 {
            let thousands = Double(number) / 1_000
            return String(format: "%.1fk", thousands)
        } else if number >= 1_000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        }
        return "\(number)"
    }

    private func trendText(_ percentage: Int) -> String {
        if percentage >= 0 {
            return "↑\(percentage)%"
        } else {
            return "↓\(abs(percentage))%"
        }
    }
}

// Helper view for stat rows
struct StatRow: View {
    let label: String
    let value: String
    let textColor: Color
    let secondaryColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textColor)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(secondaryColor)
                .monospacedDigit()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(KeystrokeMonitor())
}
