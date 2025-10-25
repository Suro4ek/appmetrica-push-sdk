import Foundation
import AppMetricaPush
import UserNotifications

@objc(AppMetricaPushInitializer)
public class AppMetricaPushInitializer: NSObject {
    
    // MARK: - Public Methods
    
    /// Инициализация AppMetrica Push SDK
    /// - Parameters:
    ///   - application: UIApplication instance
    ///   - launchOptions: Опции запуска приложения
    ///   - appGroup: App Group для расширений (опционально)
    ///   - notificationOptions: Опции для запроса разрешений на push-уведомления
    @objc public static func initialize(
        application: UIApplication,
        withLaunchOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        appGroup: String? = nil,
        notificationOptions: UNAuthorizationOptions = [.badge, .alert, .sound]
    ) {
        // Установка App Group если указан
        if let appGroup = appGroup {
            AppMetricaPush.setExtensionAppGroup(appGroup)
        }
        
        // Инициализация AppMetrica Push SDK
        AppMetricaPush.handleApplicationDidFinishLaunching(options: launchOptions)
        
        // Настройка push-уведомлений
        setupPushNotifications(for: application, options: notificationOptions)
        
        // Настройка автоматической обработки push-уведомлений
        setupNotificationDelegate()
    }
    
    /// Настройка push-уведомлений
    /// - Parameters:
    ///   - application: UIApplication instance
    ///   - options: Опции для запроса разрешений
    @objc public static func setupPushNotifications(
        for application: UIApplication,
        options: UNAuthorizationOptions = [.badge, .alert, .sound]
    ) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: options) { (granted, error) in
            if let error = error {
                print("AppMetricaPush: Failed to request notification permissions: \(error)")
            } else {
                print("AppMetricaPush: Notification permissions granted: \(granted)")
            }
        }
        application.registerForRemoteNotifications()
    }
    
    /// Настройка автоматической обработки push-уведомлений
    @objc public static func setupNotificationDelegate() {
        let delegate = AppMetricaPush.userNotificationCenterDelegate
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    /// Регистрация device token
    /// - Parameters:
    ///   - deviceToken: Device token от APNs
    ///   - environment: Окружение ("development"/"production"), если не указано - определяется автоматически
    @objc public static func registerDeviceToken(
        _ deviceToken: Data,
        environment: String? = nil
    ) {
        let pushEnvironment: AppMetricaPushEnvironment
        if let envString = environment {
            pushEnvironment = envString == "development" ? .development : .production
        } else {
            pushEnvironment = currentEnvironmentEnum()
        }
        AppMetricaPush.setDeviceTokenFrom(deviceToken, pushEnvironment: pushEnvironment)
    }
    
    /// Получение текущего окружения
    /// - Returns: String окружение для текущей конфигурации
    @objc public static func currentEnvironment() -> String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }
    
    /// Получение текущего окружения как AppMetricaPushEnvironment
    /// - Returns: AppMetricaPushEnvironment для текущей конфигурации
    private static func currentEnvironmentEnum() -> AppMetricaPushEnvironment {
        #if DEBUG
        return AppMetricaPushEnvironment.development
        #else
        return AppMetricaPushEnvironment.production
        #endif
    }
    
    /// Проверка инициализации SDK
    /// - Returns: true если SDK инициализирован
    @objc public static func isInitialized() -> Bool {
        // AppMetrica Push SDK автоматически инициализируется при вызове handleApplicationDidFinishLaunching
        return true
    }
}
