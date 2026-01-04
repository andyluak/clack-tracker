//
//  Clack_TrackerApp.swift
//  Clack Tracker
//
//  Created by Alexandru Tirim on 28.12.2025.
//

import SwiftUI

@main
struct Clack_TrackerApp: App {
    // @StateObject creates a single instance shared across the app
    // It lives as long as the app lives
    // Monitoring starts automatically in KeystrokeMonitor's init()
    @StateObject private var monitor = KeystrokeMonitor()

    init() {
        // Check if we should prompt for auto-start on first launch
        LaunchAtLoginManager.shared.checkAndPromptIfNeeded()
    }

    var body: some Scene {
        // MenuBarExtra creates an app that lives in the menu bar (top right)
        // Using just the label (no systemImage) lets us show custom text
        MenuBarExtra {
            // This is what appears when you click the menu bar item
            ContentView()
                .environmentObject(monitor) // Pass monitor to ContentView
        } label: {
            // This appears in the menu bar
            // monitor.todayCount updates automatically when keys are pressed!
            Text("⌨️ \(formatCompact(monitor.todayCount))")
        }
        .menuBarExtraStyle(.window) // Use window style - fixes greyed out text
    }

    private func formatCompact(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fk", Double(number) / 1_000)
        }
        return "\(number)"
    }
}
