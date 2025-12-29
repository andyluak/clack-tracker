//
//  launch-at-login.swift
//  Clack Tracker
//
//  Created by Alexandru Tirim on 28.12.2025.
//

import Foundation
import AppKit
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private let hasAskedKey = "hasAskedLaunchAtLogin"

    func checkAndPromptIfNeeded() {
        // Check if we've already asked the user
        let hasAsked = UserDefaults.standard.bool(forKey: hasAskedKey)

        if !hasAsked {
            // Wait a bit so the app is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showPrompt()
            }
        }
    }

    private func showPrompt() {
        let alert = NSAlert()
        alert.messageText = "Launch Clack Tracker at Login?"
        alert.informativeText = "Would you like Clack Tracker to automatically start when you log in to your Mac?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes, Auto-Start")
        alert.addButton(withTitle: "No Thanks")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // User clicked "Yes, Auto-Start"
            enableLaunchAtLogin()
        }

        // Mark that we've asked (regardless of answer)
        UserDefaults.standard.set(true, forKey: hasAskedKey)
    }

    private func enableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            // Modern approach for macOS 13+
            do {
                try SMAppService.mainApp.register()
                print("✅ Successfully registered for launch at login")
            } catch {
                print("❌ Failed to register for launch at login: \(error)")
                // Fallback to manual instructions
                showManualInstructions()
            }
        } else {
            // Older macOS versions - show manual instructions
            showManualInstructions()
        }
    }

    private func showManualInstructions() {
        let alert = NSAlert()
        alert.messageText = "Enable Auto-Start Manually"
        alert.informativeText = """
        To make Clack Tracker start automatically:

        1. Open System Settings
        2. Go to General → Login Items
        3. Click the + button
        4. Select Clack Tracker from Applications
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
