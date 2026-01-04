//
//  keystroke-monitor.swift
//  Clack Tracker
//
//  Created by Alexandru Tirim on 28.12.2025.
//

import Foundation
import AppKit
internal import Combine

// ObservableObject lets SwiftUI react when @Published properties change
class KeystrokeMonitor: ObservableObject {
    // @Published means: when this changes, SwiftUI views will update
    @Published var todayCount: Int = 0
    @Published var history: [String: Int] = [:] // Date string -> count

    // This holds our event listener (we'll need it to stop listening later)
    private var eventTap: CFMachPort?
    private var midnightTimer: Timer?

    init() {
        // Load saved count when app starts (in case app was closed during the day)
        todayCount = UserDefaults.standard.integer(forKey: "todayCount")

        // Load history from UserDefaults
        if let savedHistory = UserDefaults.standard.dictionary(forKey: "history") as? [String: Int] {
            history = savedHistory
        }

        // Check if we need to reset (in case app wasn't running at midnight)
        checkForDayChange()

        // Start midnight timer
        startMidnightTimer()

        // Start monitoring automatically
        // Delay slightly to ensure everything is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startMonitoring()
        }
    }

    // Start listening to keypresses
    func startMonitoring() {
        // Check if we have permission first
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("❌ No Accessibility permission - can't monitor keystrokes")
            requestAccessibilityPermission()
            return
        }

        print("✅ Starting keystroke monitoring...")

        // Create an event tap that listens to ALL key down events
        // CGEventMask(1 << CGEventType.keyDown.rawValue) = only listen to key presses
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        // Create the actual listener
        // self is passed as context so we can access it in the callback
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,           // Listen to all events in current session
            place: .headInsertEventTap,        // Get events before other apps
            options: .defaultTap,              // Normal mode
            eventsOfInterest: eventMask,       // Only key down events
            callback: { proxy, type, event, refcon in
                // This closure runs every time a key is pressed!
                // refcon is our KeystrokeMonitor instance
                let monitor = Unmanaged<KeystrokeMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                monitor.handleKeypress()

                // Return the event unchanged (we're just observing, not modifying)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap")
            return
        }

        eventTap = tap

        // Add the tap to the run loop so it actually runs
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✅ Monitoring started!")
    }

    // This runs every time a key is pressed
    private func handleKeypress() {
        // Update count on main thread (required for UI updates)
        DispatchQueue.main.async {
            self.todayCount += 1
            // Save to UserDefaults so it persists if app closes
            UserDefaults.standard.set(self.todayCount, forKey: "todayCount")
        }
    }

    // Request permission if we don't have it
    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }

    // Stop monitoring (cleanup)
    func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
        midnightTimer?.invalidate()
    }

    // MARK: - Midnight Reset

    private func startMidnightTimer() {
        // Calculate seconds until midnight
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let midnight = calendar.startOfDay(for: tomorrow)
        let secondsUntilMidnight = midnight.timeIntervalSince(now)

        print("⏰ Scheduling midnight reset in \(Int(secondsUntilMidnight / 3600)) hours")

        // Schedule timer to fire at midnight
        midnightTimer = Timer.scheduledTimer(withTimeInterval: secondsUntilMidnight, repeats: false) { [weak self] _ in
            self?.resetForNewDay()
            // Reschedule for next midnight
            self?.startMidnightTimer()
        }
    }

    private func checkForDayChange() {
        // Get the last saved date
        let lastDate = UserDefaults.standard.string(forKey: "lastDate") ?? ""
        let today = dateString(from: Date())

        // If date has changed, reset
        if lastDate != today && !lastDate.isEmpty {
            print("📅 Day changed from \(lastDate) to \(today) - resetting")
            // Save yesterday's count to history
            if todayCount > 0 {
                history[lastDate] = todayCount
                saveHistory()
            }
            // Reset count
            todayCount = 0
            UserDefaults.standard.set(todayCount, forKey: "todayCount")
        }

        // Update last date
        UserDefaults.standard.set(today, forKey: "lastDate")
    }

    private func resetForNewDay() {
        let yesterday = dateString(from: Date(timeIntervalSinceNow: -86400)) // 24 hours ago

        print("🌙 Midnight! Saving today's count: \(todayCount)")

        // Save today's count to history
        if todayCount > 0 {
            history[yesterday] = todayCount
            saveHistory()
        }

        // Reset count
        todayCount = 0
        UserDefaults.standard.set(todayCount, forKey: "todayCount")

        // Update last date
        UserDefaults.standard.set(dateString(from: Date()), forKey: "lastDate")
    }

    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: "history")
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Statistics

    var averageCount: Int {
        guard !history.isEmpty else { return todayCount }
        let total = history.values.reduce(0, +)
        return total / history.count
    }

    var peakDay: (date: String, count: Int)? {
        guard let peak = history.max(by: { $0.value < $1.value }) else { return nil }
        return (date: peak.key, count: peak.value)
    }

    var totalAllTime: Int {
        history.values.reduce(0, +) + todayCount
    }

    var yesterdayCount: Int {
        let yesterday = dateString(from: Date(timeIntervalSinceNow: -86400))
        return history[yesterday] ?? 0
    }

    var trendPercentage: Int? {
        guard yesterdayCount > 0 else { return nil }
        let diff = todayCount - yesterdayCount
        return Int((Double(diff) / Double(yesterdayCount)) * 100)
    }

    var last7Days: [(date: String, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get last 7 days including today
        let dates = (0..<7).compactMap { daysAgo -> (String, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let dateStr = dateString(from: date)

            if daysAgo == 0 {
                // Today
                return (dateStr, todayCount)
            } else {
                // Past days
                return (dateStr, history[dateStr] ?? 0)
            }
        }

        return dates.reversed() // Show oldest to newest
    }
}
