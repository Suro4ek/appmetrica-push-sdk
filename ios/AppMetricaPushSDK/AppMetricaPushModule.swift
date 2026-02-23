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
/// Shows banners in foreground, sends events to JS, chains to AppMetrica for tracking
class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var appMetricaDelegate: UNUserNotificationCenterDelegate?

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Send event to JS
        let body = buildEventBody(from: notification)
        PushEventEmitter.shared?.sendEvent(withName: "onPushReceived", body: body)

        // Forward to AppMetrica for tracking
        appMetricaDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: { _ in })

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
        // Send event to JS (navigation handled in JS, not by AppMetrica)
        let body = buildEventBody(from: response.notification)
        PushEventEmitter.shared?.sendEvent(withName: "onPushOpened", body: body)

        // NOTE: не прокидываем в AppMetrica — он открывает deep link в браузере
        // AppMetrica трекинг открытия делаем вручную
        let userInfo = response.notification.request.content.userInfo
        AppMetricaPush.handleRemoteNotification(userInfo)

        completionHandler()
    }
}


@objc(AppMetricaPushModule)
class AppMetricaPushModule: NSObject, RCTBridgeModule {

    // Strong reference so UNUserNotificationCenter.delegate (weak) doesn't lose it
    private static let foregroundDelegate = ForegroundNotificationDelegate()

    // MARK: - RCTBridgeModule Protocol

    static func requiresMainQueueSetup() -> Bool {
        return false
    }

    static func moduleName() -> String! {
        return "AppMetricaPushModule"
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
        AppMetricaPushModule.foregroundDelegate.appMetricaDelegate = appMetricaDelegate
        UNUserNotificationCenter.current().delegate = AppMetricaPushModule.foregroundDelegate

        if debugMode {
            print("[Push] Delegate chain: ForegroundDelegate → AppMetrica")
        }

        resolver(true)
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
