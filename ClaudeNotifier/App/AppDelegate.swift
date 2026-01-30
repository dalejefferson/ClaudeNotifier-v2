//
//  AppDelegate.swift
//  ClaudeNotifier
//
//  Application delegate managing socket server, session tracking,
//  and notification window presentation.
//

import AppKit
import SwiftUI

// MARK: - NonKeyWindow

/// A window that never becomes the key window, preventing keyboard focus theft.
/// Users can keep typing in their active app while notifications appear.
final class NonKeyWindow: NSWindow {
    override var canBecomeKey: Bool { false }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    let socketServer = SocketServer()
    private let sessionTracker = SessionTracker.shared
    private var eventObserver: NSObjectProtocol?

    // Notification window stacking
    private var notificationWindows: [NSWindow] = []
    private let maxNotificationCount = 5
    private let notificationSpacing: CGFloat = 10
    private let notificationWindowWidth: CGFloat = 400
    private let notificationWindowHeight: CGFloat = 180

    // Deferred notification for when subagents are still active
    private var pendingStopEvent: ClaudeEvent?

    // Idle input reminder
    private var idleReminderTimer: Timer?
    private let idleReminderDelay: TimeInterval = 30.0

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Cleanup old events
        EventStore.shared.performCleanup()

        // Start the socket server
        Task { @MainActor in
            socketServer.start()
        }

        // Observe Claude events
        eventObserver = NotificationCenter.default.addObserver(
            forName: .claudeEventReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.object as? ClaudeEvent else { return }
            self?.handleClaudeEvent(event)
        }

        // Make MenuBarExtra window draggable
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.makeMenuBarWindowDraggable()
        }
    }

    private func makeMenuBarWindowDraggable() {
        // Find the MenuBarExtra window and make it draggable
        for window in NSApp.windows {
            if window.title.isEmpty && window.level == .popUpMenu {
                window.isMovableByWindowBackground = true
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush all pending batched writes
        EventStore.shared.flushToDisk()
        SessionTracker.shared.flush()

        if let observer = eventObserver {
            NotificationCenter.default.removeObserver(observer)
            eventObserver = nil
        }
        Task { @MainActor in
            socketServer.stop()
        }
        sessionTracker.save()
        cancelIdleReminderTimer()
        closeAllNotificationWindows()
    }

    // MARK: - Event Handling

    private func handleClaudeEvent(_ event: ClaudeEvent) {
        // Any Claude activity cancels the idle reminder timer
        cancelIdleReminderTimer()

        // Track subagents: if we see activity from an unknown session that isn't a main session start,
        // it's likely a subagent. Register it so we can count active agents.
        if event.type != .sessionStart && !event.sessionId.isEmpty {
            if !sessionTracker.isTracking(sessionId: event.sessionId) {
                // This session isn't a main session - it's a subagent
                sessionTracker.recordSubagentStart(sessionId: event.sessionId)
            }
        }

        switch event.type {
        case .sessionStart:
            // Record session start time, no notification
            sessionTracker.recordStart(sessionId: event.sessionId, timestamp: event.timestamp)
            // Trigger stats refresh for model detection
            StatsReader.shared.forceRefresh()
            return

        case .notification:
            // Skip idle prompt notifications - only notify on finished generations
            if event.matcher == .idlePrompt {
                return
            }
            fallthrough

        case .subagentStop:
            // Track subagent completion - remove from both tracking sets
            sessionTracker.recordSubagentStop(sessionId: event.sessionId)
            sessionTracker.clearSession(sessionId: event.sessionId)

            // If this was the last subagent and we have a pending stop event, show it now
            if sessionTracker.activeSubagentCount == 0, let pending = pendingStopEvent {
                pendingStopEvent = nil
                showNotificationWindow(for: pending)
            }
            return

        case .stop:
            // Enrich event with session data
            var enrichedEvent = event

            // Add duration
            if let duration = sessionTracker.getDuration(sessionId: event.sessionId) {
                enrichedEvent.duration = duration
            }

            // Clear session if completed (do this before async work)
            if event.stopReason != .interrupt {
                sessionTracker.clearSession(sessionId: event.sessionId)
            }

            // Add task summary from transcript if available (background thread)
            if enrichedEvent.taskSummary == nil && !event.transcriptPath.isEmpty {
                // Parse transcript on background thread to avoid blocking UI
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    let (summary, _, _) = TranscriptParser.parseTranscript(at: event.transcriptPath)

                    DispatchQueue.main.async {
                        var finalEvent = enrichedEvent
                        finalEvent.taskSummary = summary

                        // Persist enriched event to history
                        EventStore.shared.save(event: finalEvent)

                        self?.showOrDeferNotification(for: finalEvent)
                    }
                }
            } else {
                // No transcript parsing needed - save and show immediately
                EventStore.shared.save(event: enrichedEvent)
                showOrDeferNotification(for: enrichedEvent)
            }
        }
    }

    // MARK: - Deferred Notification Logic

    /// Shows the notification immediately if no subagents are active,
    /// otherwise defers it until all subagents complete.
    private func showOrDeferNotification(for event: ClaudeEvent) {
        // Interrupts always show immediately
        if event.stopReason == .interrupt {
            showNotificationWindow(for: event)
            return
        }

        // If subagents are still active, defer the notification
        if sessionTracker.activeSubagentCount > 0 {
            pendingStopEvent = event
        } else {
            showNotificationWindow(for: event)
        }
    }

    // MARK: - Window Management

    private func showNotificationWindow(for event: ClaudeEvent, isIdleReminder: Bool = false) {
        // Enforce max notification count - remove oldest if at limit
        if notificationWindows.count >= maxNotificationCount {
            let oldest = notificationWindows.removeFirst()
            oldest.close()
        }

        let window = NonKeyWindow(
            contentRect: NSRect(x: 0, y: 0, width: notificationWindowWidth, height: notificationWindowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let contentView = NotificationWindowView(event: event, isIdleReminder: isIdleReminder) { [weak self, weak window] in
            guard let self = self, let window = window else { return }
            self.dismissNotificationWindow(window)
        }
        .padding(20) // Padding for shadow to render

        // Configure borderless transparent window
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // We use SwiftUI shadows
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false

        // Add to stack and position all windows
        notificationWindows.append(window)
        repositionNotificationWindows()

        // Show without stealing focus
        presentNotification(window: window)

        // Start idle timer for stop events (not for idle reminders themselves)
        if event.type == .stop && !isIdleReminder {
            startIdleReminderTimer()
        }
    }

    private func dismissNotificationWindow(_ window: NSWindow) {
        window.close()
        notificationWindows.removeAll { $0 === window }
        repositionNotificationWindows()
    }

    private func closeAllNotificationWindows() {
        for window in notificationWindows {
            window.close()
        }
        notificationWindows.removeAll()
    }

    /// Positions all notification windows stacked from top-right.
    /// Newest notification (last in array) is at the top, older ones stack below.
    private func repositionNotificationWindows() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        for (index, window) in notificationWindows.enumerated() {
            let stackIndex = notificationWindows.count - 1 - index
            let x = screenFrame.maxX - notificationWindowWidth - 10
            let y = screenFrame.maxY - notificationWindowHeight - 10
                - (CGFloat(stackIndex) * (notificationWindowHeight + notificationSpacing))

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
    }

    /// Shows the window without stealing keyboard focus from the active app.
    private func presentNotification(window: NSWindow) {
        window.orderFrontRegardless()
    }

    // MARK: - Idle Reminder Timer

    private func startIdleReminderTimer() {
        cancelIdleReminderTimer()
        idleReminderTimer = Timer.scheduledTimer(withTimeInterval: idleReminderDelay, repeats: false) { [weak self] _ in
            self?.showIdleReminder()
        }
    }

    private func cancelIdleReminderTimer() {
        idleReminderTimer?.invalidate()
        idleReminderTimer = nil
    }

    private func showIdleReminder() {
        idleReminderTimer = nil

        let idleEvent = ClaudeEvent(
            type: .notification,
            matcher: .idlePrompt,
            taskSummary: "Claude is waiting for your input"
        )
        showNotificationWindow(for: idleEvent, isIdleReminder: true)
    }

}
