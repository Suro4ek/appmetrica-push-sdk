# @moseffect21/appmetrica-push-sdk

React Native библиотека для интеграции с Yandex AppMetrica Push SDK.

## 📚 Документация

- [Интеграционный гайд](./docs/INTEGRATION_GUIDE.md) - подробное руководство по интеграции
- [Руководство для аналитиков](./docs/ANALYTICS_GUIDE.md) - настройка push кампаний
- [Настройка Silent Push](./docs/SILENT_PUSH_SETUP.md) - настройка silent push уведомлений

## 🚀 Установка

```bash
# Через npm
npm install @moseffect21/appmetrica-push-sdk@git+https://github.com/moseffect21/appmetrica-push-sdk.git

# Через yarn
yarn add @moseffect21/appmetrica-push-sdk@git+https://github.com/moseffect21/appmetrica-push-sdk.git
```

## ⚡ Быстрый старт

### 1. Настройка нативного кода

#### iOS (AppDelegate.swift)

```swift
import AppMetricaPushSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    AppMetricaPushInitializer.initialize(application: application, withLaunchOptions: launchOptions)
    return true
}

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    AppMetricaPushInitializer.registerDeviceToken(deviceToken)
}
```

#### Android

Инициализация происходит автоматически через React Native модуль.

### 2. Использование в React Native

```typescript
import { AppMetricaPush } from "@moseffect21/appmetrica-push-sdk";

// Инициализация (обязательно для Android)
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

## 📱 API

### Основные методы

- `initialize(config)` - инициализация SDK
- `isNotificationFromAppMetrica(notification)` - проверка источника уведомления
- `getSDKInfo()` - получение информации о SDK
- `getUserData(notification)` - извлечение пользовательских данных

### Утилиты

- `initializeAppMetricaPush(config)` - инициализация с проверками
- `isSDKInitialized()` - проверка инициализации
- `getCurrentConfig()` - текущая конфигурация

### React Hook

- `useAppMetricaPush()` - хук для работы с SDK

## 🔧 Зависимости

### Android (android/app/build.gradle)

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

### iOS

```bash
cd ios && pod install
```

## ✨ Особенности

- ✅ **Автоматическая инициализация** - нативная инициализация для iOS, JS для Android
- ✅ **TypeScript поддержка** - полная типизация
- ✅ **Кросс-платформенность** - единый API для iOS и Android
- ✅ **Простая интеграция** - минимум настройки

## 📋 Требования

- React Native >= 0.60.0
- Android API 21+
- iOS 11.0+

## 🐛 Troubleshooting

### Частые проблемы

1. **"AppMetricaPushModule is not available"**

   - Проверьте установку библиотеки
   - Выполните `cd ios && pod install` (iOS)
   - Пересоберите проект

2. **Push-уведомления не приходят**
   - Проверьте настройки Firebase/APNs
   - Убедитесь в правильной инициализации

## 📄 Лицензия

MIT

## 🔗 Ссылки

- [AppMetrica Push SDK](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/push-sdk/about.html)
- [GitHub](https://github.com/moseffect21/appmetrica-push-sdk)
