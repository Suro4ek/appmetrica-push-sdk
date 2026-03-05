import Foundation
import React

@objc(PushEventEmitter)
class PushEventEmitter: RCTEventEmitter {
    static var shared: PushEventEmitter?

    /// Tracks whether JS has active listeners.
    /// Used by ForegroundNotificationDelegate to decide: send directly or buffer.
    private(set) var hasActiveListeners = false

    override init() {
        super.init()
        PushEventEmitter.shared = self
    }

    override static func requiresMainQueueSetup() -> Bool {
        return false
    }

    override static func moduleName() -> String! {
        return "PushEventEmitter"
    }

    override func supportedEvents() -> [String]! {
        return ["onPushReceived", "onPushOpened"]
    }

    /// Called by RN when JS subscribes via addListener — JS is ready to receive events.
    override func startObserving() {
        hasActiveListeners = true
        // Flush notification that was buffered during cold start
        DispatchQueue.main.async {
            ForegroundNotificationDelegate.shared.flushPendingNotifications()
        }
    }

    override func stopObserving() {
        hasActiveListeners = false
    }
}
