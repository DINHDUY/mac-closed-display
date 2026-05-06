// MARK: - StatusBarController.swift
// Manages menu bar icon and user notifications for ClosedDisplay state changes.
// Lightweight implementation with minimal memory footprint.

import Cocoa
import UserNotifications

/// Controller for menu bar icon and notifications
class StatusBarController: NSObject, NSMenuDelegate {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private let statusBar = NSStatusBar.system
    private var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Constants.statusBarEnabledKey)
            updateStatusBarIcon()
            updateTooltip()
            postStateChangeNotification()
        }
    }
    private var isSuspended: Bool = false {
        didSet {
            updateStatusBarIcon()
            updateTooltip()
            updateMenuItems()
            if isSuspended {
                print("[StatusBar] ClosedDisplay suspended - lid closure will not be prevented")
            } else {
                print("[StatusBar] ClosedDisplay resumed - lid closure prevention active")
            }
        }
    }
    
    // MARK: - Icons
    
    private let enabledIcon: NSImage = {
        let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "ClosedDisplay Enabled")!
        image.isTemplate = true
        return image
    }()
    
    private let disabledIcon: NSImage = {
        let image = NSImage(systemSymbolName: "circle", accessibilityDescription: "ClosedDisplay Disabled")!
        image.isTemplate = true
        return image
    }()
    
    private let suspendedIcon: NSImage = {
        let image = NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: "ClosedDisplay Suspended")!
        image.isTemplate = true
        return image
    }()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Load saved state, default to enabled on first launch (FR: default on/running)
        self.isEnabled = UserDefaults.standard.object(forKey: Constants.statusBarEnabledKey) as? Bool ?? true
        
        // Request notification permissions (only if running as proper app bundle)
        if Bundle.main.bundleIdentifier != nil {
            requestNotificationPermissions()
            
            // If enabled on launch, post initial notification
            if isEnabled {
                postInitialNotification()
            }
        }
        
        // Setup status bar item
        setupStatusBar()
        
        // Check for first-run permissions setup
        checkPermissionsOnFirstRun()
    }
    
    // MARK: - Status Bar Setup
    
    private func setupStatusBar() {
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else { return }
        
        // Set initial icon
        button.image = isEnabled ? enabledIcon : disabledIcon
        
        // Create and assign menu
        let menu = NSMenu()
        menu.delegate = self
        
        // Toggle menu item
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Disable ClosedDisplay" : "Enable ClosedDisplay",
            action: #selector(toggleState),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.tag = 1
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Suspend menu item
        let suspendItem = NSMenuItem(
            title: "Suspend (Allow Sleep on Lid Close)",
            action: #selector(toggleSuspend),
            keyEquivalent: ""
        )
        suspendItem.target = self
        suspendItem.tag = 2
        menu.addItem(suspendItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Setup Permissions menu item
        let setupPermissionsItem = NSMenuItem(
            title: "Setup Permissions...",
            action: #selector(setupPermissions),
            keyEquivalent: ""
        )
        setupPermissionsItem.target = self
        setupPermissionsItem.tag = 3
        menu.addItem(setupPermissionsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About item
        let aboutItem = NSMenuItem(
            title: "About ClosedDisplay",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Assign menu to status item
        statusItem?.menu = menu
        
        // Set tooltip AFTER menu is assigned
        button.toolTip = getTooltipText()
    }
    
    private func getTooltipText() -> String {
        if !isEnabled {
            return "ClosedDisplay OFF - Lid closure will sleep the Mac"
        } else if isSuspended {
            return "ClosedDisplay SUSPENDED - Temporarily allowing sleep on lid close"
        } else {
            return "ClosedDisplay ON - You can close the lid without interrupting background processes"
        }
    }
    
    // MARK: - State Management
    
    @objc private func toggleState() {
        isEnabled.toggle()
        
        // If enabling, clear suspend state
        if isEnabled {
            isSuspended = false
        }
        
        updateMenuItems()
    }
    
    @objc private func toggleSuspend() {
        // Can only suspend if enabled
        guard isEnabled else { return }
        
        isSuspended.toggle()
    }
    
    private func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }
        
        if !isEnabled {
            button.image = disabledIcon
        } else if isSuspended {
            button.image = suspendedIcon
        } else {
            button.image = enabledIcon
        }
    }
    
    private func updateTooltip() {
        guard let button = statusItem?.button else { return }
        button.toolTip = getTooltipText()
    }
    
    private func updateMenuItems() {
        guard let menu = statusItem?.menu else { return }
        
        // Update toggle item (tag 1)
        if let toggleItem = menu.items.first(where: { $0.tag == 1 }) {
            toggleItem.title = isEnabled ? "Disable ClosedDisplay" : "Enable ClosedDisplay"
        }
        
        // Update suspend item (tag 2)
        if let suspendItem = menu.items.first(where: { $0.tag == 2 }) {
            if isEnabled {
                suspendItem.title = isSuspended ? "Resume ClosedDisplay" : "Suspend (Allow Sleep on Lid Close)"
                suspendItem.isEnabled = true
            } else {
                suspendItem.title = "Suspend (Allow Sleep on Lid Close)"
                suspendItem.isEnabled = false
            }
        }
    }
    
    // MARK: - NSMenuDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update menu items before displaying
        updateMenuItems()
    }
    
    // MARK: - Public API
    
    /// Returns current enabled state
    var currentState: Bool {
        return isEnabled && !isSuspended
    }
    
    /// Returns true if ClosedDisplay is suspended
    var isSuspendedState: Bool {
        return isSuspended
    }
    
    /// Programmatically set state (used by SessionManager)
    func setState(_ enabled: Bool, notify: Bool = true) {
        guard isEnabled != enabled else { return }
        
        let shouldNotify = notify
        isEnabled = enabled
        
        if !shouldNotify {
            // Already notified via didSet, skip duplicate
            return
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermissions() {
        // Only request permissions if running as proper app bundle
        guard Bundle.main.bundleIdentifier != nil else { return }
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[StatusBar] Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func postInitialNotification() {
        // Only post notifications if running as proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            print("[StatusBar] Notifications unavailable (not running as app bundle)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "ClosedDisplay"
        content.body = "ClosedDisplay is enabled and running"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[StatusBar] Failed to post initial notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func postStateChangeNotification() {
        // Only post notifications if running as proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            print("[StatusBar] State changed to: \(isEnabled ? "enabled" : "disabled")")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "ClosedDisplay"
        content.body = isEnabled ? "ClosedDisplay enabled" : "ClosedDisplay disabled"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[StatusBar] Failed to post state change notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Permissions Setup

    private func checkPermissionsOnFirstRun() {
        let sudoersPath = "/private/etc/sudoers.d/closeddisplay"
        let promptShownKey = "com.closed-display.setupPromptShown"

        guard !FileManager.default.fileExists(atPath: sudoersPath),
              !UserDefaults.standard.bool(forKey: promptShownKey) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupPermissions()
        }
    }

    @objc private func setupPermissions() {
        let sudoersPath = "/private/etc/sudoers.d/closeddisplay"
        let promptShownKey = "com.closed-display.setupPromptShown"

        // Already configured
        if FileManager.default.fileExists(atPath: sudoersPath) {
            let alert = NSAlert()
            alert.messageText = "Permissions Already Configured"
            alert.informativeText = "The passwordless permissions for pmset are already set up."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // Mark as prompted so we never auto-show again, even on Cancel
        UserDefaults.standard.set(true, forKey: promptShownKey)

        // Approval dialog
        let approvalAlert = NSAlert()
        approvalAlert.messageText = "Setup Passwordless Permissions"
        approvalAlert.informativeText = "ClosedDisplay needs to create a sudoers rule so it can run pmset without a password prompt. Your macOS administrator password will be required."
        approvalAlert.alertStyle = .informational
        approvalAlert.addButton(withTitle: "Setup")
        approvalAlert.addButton(withTitle: "Cancel")
        guard approvalAlert.runModal() == .alertFirstButtonReturn else { return }

        // Validate username — guard against shell injection
        let username = NSUserName()
        let usernamePattern = "^[a-zA-Z0-9._-]+$"
        guard let regex = try? NSRegularExpression(pattern: usernamePattern),
              regex.firstMatch(in: username, range: NSRange(username.startIndex..., in: username)) != nil else {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Invalid Username"
            errorAlert.informativeText = "Your system username contains characters that are not allowed in sudoers configuration."
            errorAlert.alertStyle = .warning
            errorAlert.addButton(withTitle: "OK")
            errorAlert.runModal()
            return
        }

        // Build shell command: write → validate → install → lock down → clean up
        let shellCmd = [
            "printf '%s ALL=(ALL) NOPASSWD: /usr/bin/pmset\\n' '\(username)' | /usr/bin/tee /tmp/closeddisplay_sudoers > /dev/null",
            "/usr/sbin/visudo -cf /tmp/closeddisplay_sudoers",
            "/bin/cp /tmp/closeddisplay_sudoers /private/etc/sudoers.d/closeddisplay",
            "/bin/chmod 440 /private/etc/sudoers.d/closeddisplay",
            "/bin/rm -f /tmp/closeddisplay_sudoers"
        ].joined(separator: " && ")

        let appleScriptSource = "do shell script \"\(shellCmd)\" with administrator privileges"

        var scriptError: NSDictionary?
        guard let script = NSAppleScript(source: appleScriptSource) else {
            showSetupError("Failed to initialise AppleScript.")
            return
        }
        script.executeAndReturnError(&scriptError)

        if let err = scriptError {
            let msg = err["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
            showSetupError(msg)
        } else {
            let successAlert = NSAlert()
            successAlert.messageText = "Permissions Configured"
            successAlert.informativeText = "ClosedDisplay can now run pmset without a password prompt."
            successAlert.alertStyle = .informational
            successAlert.addButton(withTitle: "OK")
            successAlert.runModal()
        }
    }

    private func showSetupError(_ description: String) {
        let alert = NSAlert()
        alert.messageText = "Setup Failed"
        alert.informativeText = "Setup failed: \(description)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Menu Actions
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ClosedDisplay"
        alert.informativeText = "A utility to keep your Mac awake with the lid closed.\n\nVersion 1.0.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let statusItem = statusItem {
            statusBar.removeStatusItem(statusItem)
        }
    }
}
