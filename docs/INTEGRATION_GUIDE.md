# AppMetrica Push SDK - Интеграция

## 🚀 Быстрая установка

### 1. Установка библиотеки

```bash
# Через npm
npm install @moseffect21/appmetrica-push-sdk@git+https://github.com/moseffect21/appmetrica-push-sdk.git

# Через yarn
yarn add @moseffect21/appmetrica-push-sdk@git+https://github.com/moseffect21/appmetrica-push-sdk.git
```

### 2. Настройка зависимостей

#### Android (android/app/build.gradle)

```gradle
dependencies {
    // Firebase Cloud Messaging
    implementation platform('com.google.firebase:firebase-bom:33.2.0')
    implementation 'com.google.firebase:firebase-messaging'

    // AppMetrica Push SDK
    implementation("io.appmetrica.analytics:push:4.2.1")
    implementation("io.appmetrica.analytics:push-provider-firebase:4.2.1")
}
```

#### iOS

```bash
cd ios && pod install
```

## 📱 Настройка нативного кода

### iOS (AppDelegate.swift)

```swift
import AppMetricaPushSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    // Инициализация AppMetrica Push SDK
    AppMetricaPushInitializer.initialize(application: application, withLaunchOptions: launchOptions)

    return true
}

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Регистрация device token
    AppMetricaPushInitializer.registerDeviceToken(deviceToken)
}
```

### Android

**Инициализация происходит автоматически через React Native модуль при вызове `AppMetricaPush.initialize()` в JavaScript коде.**

## 💻 Использование в React Native

```typescript
import { AppMetricaPush } from "@moseffect21/appmetrica-push-sdk";

// Инициализация (обязательно для Android, опционально для iOS)
await AppMetricaPush.initialize({
  debugMode: __DEV__,
});

// Проверка уведомления
const isFromAppMetrica = await AppMetricaPush.isNotificationFromAppMetrica(
  notification
);

// Получение информации о SDK
const sdkInfo = await AppMetricaPush.getSDKInfo();

// Извлечение пользовательских данных
const userData = await AppMetricaPush.getUserData(notification);
```

### Различия между платформами

- **iOS**: Инициализация происходит в `AppDelegate.swift` через `AppMetricaPushInitializer`
- **Android**: Инициализация происходит через React Native модуль при вызове `AppMetricaPush.initialize()`

## 🔧 Дополнительные настройки

### Настройка Firebase (Android)

1. Добавьте `google-services.json` в `android/app/`
2. Включите Firebase в `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### Настройка APNs (iOS)

1. Включите Push Notifications в Xcode
2. Настройте сертификаты в Apple Developer Console

## 📚 API Reference

### Основные методы

- `initialize(config)` - Инициализация SDK
- `isNotificationFromAppMetrica(notification)` - Проверка уведомления
- `getSDKInfo()` - Информация о SDK
- `getUserData(notification)` - Пользовательские данные

### Утилиты

- `initializeAppMetricaPush(config)` - Инициализация с проверками
- `isSDKInitialized()` - Проверка инициализации
- `getCurrentConfig()` - Текущая конфигурация

## 🐛 Troubleshooting

### Частые проблемы

1. **"AppMetricaPushModule is not available"**

   - Проверьте, что библиотека правильно установлена
   - Выполните `cd ios && pod install` (iOS)
   - Пересоберите проект

2. **Push-уведомления не приходят**

   - Проверьте настройки Firebase/APNs
   - Убедитесь, что device token регистрируется
   - Проверьте логи в консоли

3. **Ошибки компиляции**
   - Очистите кэш: `npx react-native start --reset-cache`
   - Пересоберите проект полностью

## 📞 Поддержка

- GitHub: [moseffect21/appmetrica-push-sdk](https://github.com/moseffect21/appmetrica-push-sdk)
- Документация: [AppMetrica Push SDK](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/push-sdk/about.html)
