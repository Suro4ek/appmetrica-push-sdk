import Foundation
import React
import AppMetricaPush
import UserNotifications

// MARK: - Data Extension for Hex String
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

// MARK: - Foreground Notification Delegate
/// Shows banners in foreground, sends events to JS, chains to AppMetrica for tracking.
/// Installs itself as UNUserNotificationCenter.delegate early to prevent
/// AppMetrica/system from opening deep links in Safari on cold start.
class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationDelegate()

    /// Previous delegate (e.g. expo-notifications) — we forward to it for tracking
    var appMetricaDelegate: UNUserNotificationCenterDelegate?

    private static let udKey = "com.appmetricapush.initialNotification"

    /// In-memory buffer (fast path)
    private(set) var initialNotification: [String: Any]?

    override init() {
        super.init()
    }

    /// Set self as UNUserNotificationCenter.delegate.
    /// Saves the existing delegate (e.g. expo-notifications) for forwarding.
    func installAsDelegateIfNeeded() {
        let center = UNUserNotificationCenter.current()
        if !(center.delegate is ForegroundNotificationDelegate) {
            let existingDelegate = center.delegate
            if existingDelegate != nil && appMetricaDelegate == nil {
                appMetricaDelegate = existingDelegate
            }
            center.delegate = self
        }
    }

    /// Flush buffered notification opened event to JS (called when PushEventEmitter is ready)
    func flushPendingNotifications() {
        guard let pending = initialNotification, let emitter = PushEventEmitter.shared else { return }
        emitter.sendEvent(withName: "onPushOpened", body: pending)
        // Don't clear here — getInitialNotification() might still need it
    }

    /// Consume the initial notification (called from getInitialNotification).
    /// Checks in-memory buffer first, then UserDefaults fallback.
    func consumeInitialNotification() -> [String: Any]? {
        let ud = UserDefaults.standard
        defer { ud.removeObject(forKey: ForegroundNotificationDelegate.udKey) }

        if let notification = initialNotification {
            initialNotification = nil
            return notification
        }

        // Fallback: cold start notification was persisted before JS was ready
        guard let data = ud.data(forKey: ForegroundNotificationDelegate.udKey),
              let notification = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        return notification
    }

    /// Extract deep link URL from yamp data
    private func extractDeepLink(from userInfo: [AnyHashable: Any]) -> String? {
        guard let yamp = userInfo["yamp"] else { return nil }

        // yamp can be a dictionary or a string
        if let yampDict = yamp as? [String: Any], let link = yampDict["l"] as? String {
            return link
        }

        // If yamp is a string representation, try to parse "l" value
        let yampStr = "\(yamp)"
        if let range = yampStr.range(of: "l = \""),
           let endRange = yampStr.range(of: "\";", range: range.upperBound..<yampStr.endIndex) {
            return String(yampStr[range.upperBound..<endRange.lowerBound])
        }

        return nil
    }

    /// Build event body from notification
    private func buildEventBody(from notification: UNNotification) -> [String: Any] {
        let content = notification.request.content
        let userInfo = content.userInfo

        var body: [String: Any] = [
            "title": content.title,
            "body": content.body,
        ]

        // Extract deep link from yamp
        if let deepLink = extractDeepLink(from: userInfo) {
            body["deepLink"] = deepLink
        }

        // Extract userData from AppMetrica
        let userData = AppMetricaPush.userData(forNotification: userInfo)
        if let userData = userData {
            body["userData"] = userData
        }

        return body
    }

    /// Check if notification is from AppMetrica
    private func isAppMetricaNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        return userInfo["yamp"] != nil
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Not from AppMetrica → forward to previous delegate (expo-notifications, etc.)
        guard isAppMetricaNotification(userInfo) else {
            if let prev = appMetricaDelegate {
                prev.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            } else {
                if #available(iOS 14.0, *) {
                    completionHandler([.banner, .sound, .badge, .list])
                } else {
                    completionHandler([.alert, .sound, .badge])
                }
            }
            return
        }

        // AppMetrica notification — handle ourselves
        let body = buildEventBody(from: notification)
        PushEventEmitter.shared?.sendEvent(withName: "onPushReceived", body: body)

        // Show banner in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Not from AppMetrica → forward to previous delegate
        guard isAppMetricaNotification(userInfo) else {
            if let prev = appMetricaDelegate {
                prev.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
            } else {
                completionHandler()
            }
            return
        }

        // AppMetrica notification — handle ourselves
        let body = buildEventBody(from: response.notification)

        // Persist to UserDefaults so getInitialNotification() can read it
        // regardless of JS bridge / event listener timing on cold start
        if let data = try? JSONSerialization.data(withJSONObject: body) {
            UserDefaults.standard.set(data, forKey: ForegroundNotificationDelegate.udKey)
        }

        if let emitter = PushEventEmitter.shared, emitter.hasActiveListeners {
            emitter.sendEvent(withName: "onPushOpened", body: body)
        } else {
            initialNotification = body
        }

        completionHandler()
    }
}


@objc(AppMetricaPushModule)
class AppMetricaPushModule: NSObject, RCTBridgeModule {

    // MARK: - RCTBridgeModule Protocol

    /// Must be true so the module is instantiated during bridge init
    /// (which happens inside application:didFinishLaunchingWithOptions:).
    /// This ensures our notification delegate is installed before iOS
    /// delivers didReceiveNotificationResponse on cold start.
    static func requiresMainQueueSetup() -> Bool {
        return true
    }

    static func moduleName() -> String! {
        return "AppMetricaPushModule"
    }

    override init() {
        super.init()
        // Install notification delegate as early as possible.
        // With requiresMainQueueSetup=true this runs during bridge init,
        // which is inside didFinishLaunchingWithOptions — before iOS calls
        // didReceiveNotificationResponse.
        ForegroundNotificationDelegate.shared.installAsDelegateIfNeeded()
    }

    // MARK: - Initialization

    @objc
    func initialize(_ config: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let debugMode = config["debugMode"] as? Bool ?? false

        DispatchQueue.main.async {
            self.performInitialization(config: config, debugMode: debugMode, resolver: resolver, rejecter: rejecter)
        }
    }

    private func performInitialization(config: NSDictionary, debugMode: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        // 1. App Group
        if let appGroup = config["appGroup"] as? String {
            AppMetricaPush.setExtensionAppGroup(appGroup)
        }

        // 2. Initialize AppMetrica Push SDK
        AppMetricaPush.handleApplicationDidFinishLaunching(options: nil)

        // 3. Setup delegate chain: ForegroundDelegate → AppMetrica delegate
        let appMetricaDelegate = AppMetricaPush.userNotificationCenterDelegate
        ForegroundNotificationDelegate.shared.appMetricaDelegate = appMetricaDelegate
        ForegroundNotificationDelegate.shared.installAsDelegateIfNeeded()

        if debugMode {
            print("[Push] Delegate chain: ForegroundDelegate → AppMetrica")
        }

        resolver(true)
    }

    // MARK: - Initial Notification (cold start)

    /// Returns the notification that launched the app from killed state.
    /// This is the most reliable way to handle cold-start deep links —
    /// JS calls this after subscribing to events.
    @objc
    func getInitialNotification(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let notification = ForegroundNotificationDelegate.shared.consumeInitialNotification()
            resolver(notification)
        }
    }

    // MARK: - Notification Analysis

    @objc
    func isNotificationFromAppMetrica(_ notification: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let notificationDict = notification as? [AnyHashable : Any] ?? [:]
            let isRelated = AppMetricaPush.isNotificationRelated(toSDK: notificationDict)
            resolver(isRelated)
        }
    }

    // MARK: - SDK Information

    @objc
    func getSDKInfo(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            resolver([
                "version": "3.2.0",
                "platform": "ios",
                "sdkName": "AppMetrica Push SDK",
                "libraryVersion": "1.0.0"
            ])
        }
    }

    // MARK: - User Data Extraction

    @objc
    func getUserData(_ notification: NSDictionary, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            let notificationDict = notification as? [AnyHashable : Any] ?? [:]
            let userData = AppMetricaPush.userData(forNotification: notificationDict)
            resolver(userData)
        }
    }

    // MARK: - Device Token Registration

    @objc
    func registerDeviceToken(_ deviceToken: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            var tokenData: Data?

            if deviceToken.count % 2 == 0 && deviceToken.allSatisfy({ $0.isHexDigit }) {
                tokenData = Data(hexString: deviceToken)
            }

            if tokenData == nil {
                tokenData = deviceToken.data(using: .utf8)
            }

            guard let finalTokenData = tokenData else {
                rejecter("INVALID_TOKEN", "Failed to convert device token to Data", nil)
                return
            }

            #if DEBUG
            let pushEnvironment = AppMetricaPushEnvironment.development
            #else
            let pushEnvironment = AppMetricaPushEnvironment.production
            #endif

            AppMetricaPush.setDeviceTokenFrom(finalTokenData, pushEnvironment: pushEnvironment)
            resolver(true)
        }
    }
}
