import Foundation
import React

@objc(PushEventEmitter)
class PushEventEmitter: RCTEventEmitter {
    static var shared: PushEventEmitter?

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

    override func startObserving() {}
    override func stopObserving() {}
}
