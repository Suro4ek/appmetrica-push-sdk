# Полное руководство по интеграции AppMetrica Push SDK

## Содержание

1. [Обзор](#обзор)
2. [Установка](#установка)
3. [Настройка зависимостей](#настройка-зависимостей)
4. [Настройка нативного кода](#настройка-нативного-кода)
5. [Использование в React Native](#использование-в-react-native)
6. [API Reference](#api-reference)
7. [Примеры использования](#примеры-использования)
8. [Troubleshooting](#troubleshooting)

## Обзор

`@suro4ek/appmetrica-push-sdk` - это React Native библиотека для интеграции с Yandex AppMetrica Push SDK. Библиотека предоставляет единый API для работы с push-уведомлениями на iOS и Android.

### Основные возможности

- ✅ **Кросс-платформенность** - единый API для iOS и Android
- ✅ **TypeScript поддержка** - полная типизация
- ✅ **Автоматическая обработка** - silent push уведомления
- ✅ **Простая интеграция** - минимум настройки
- ✅ **Firebase интеграция** - поддержка APNS токенов через Firebase

## Установка

### 1. Установка библиотеки

```bash
# Через npm
npm install @suro4ek/appmetrica-push-sdk

# Через yarn
yarn add @suro4ek/appmetrica-push-sdk

# Через pnpm
pnpm add @suro4ek/appmetrica-push-sdk
```

### 2. Установка зависимостей

#### React Native Firebase

```bash
npm install @react-native-firebase/messaging
```

#### AppMetrica (обязательно)

```bash
npm install @appmetrica/react-native-analytics
```

#### iOS

```bash
cd ios && pod install
```

## Настройка зависимостей

### Android

#### 1. Firebase Cloud Messaging

Добавьте в `android/app/build.gradle`:

```gradle
dependencies {
    // Firebase Cloud Messaging
    implementation platform('com.google.firebase:firebase-bom:33.2.0')
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-messaging-ktx'
}

// В конце файла
apply plugin: 'com.google.gms.google-services'
```

#### 2. Google Services

Добавьте в `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### 3. Google Services JSON

Скачайте `google-services.json` из Firebase Console и поместите в `android/app/`

### iOS

#### 1. Firebase Configuration

Скачайте `GoogleService-Info.plist` из Firebase Console и добавьте в Xcode проект

#### 2. Push Notifications

Включите Push Notifications в Xcode:

1. Откройте проект в Xcode
2. Выберите ваш target
3. Перейдите в "Signing & Capabilities"
4. Нажмите "+ Capability"
5. Добавьте "Push Notifications"

## Настройка нативного кода

### Android

#### 1. AndroidManifest.xml

Добавьте в `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Silent Push Receiver для AppMetrica Push SDK -->
    <receiver android:name="com.appmetricapush.SilentPushReceiver"
              android:exported="false">
        <intent-filter>
            <action android:name="com.appmetricapush.action.ymp.SILENT_PUSH_RECEIVE"/>
        </intent-filter>
    </receiver>

    <!-- Firebase Messaging Service для интеграции с AppMetrica Push SDK -->
    <service android:name="com.appmetricapush.FirebaseMessagingMainService"
             android:enabled="true"
             android:exported="false">
        <intent-filter android:priority="100">
            <action android:name="com.google.firebase.MESSAGING_EVENT"/>
        </intent-filter>
    </service>

    <!-- Отключаем стандартный AppMetrica Messaging Service -->
    <service android:name="io.appmetrica.analytics.push.provider.firebase.AppMetricaMessagingService"
             android:enabled="false"
             tools:node="remove"/>

    <!-- Иконка уведомлений по умолчанию для AppMetrica Push SDK -->
    <meta-data android:name="io.appmetrica.analytics.push.default_notification_icon"
               android:resource="@drawable/ic_stat_notification"/>
</application>
```

#### 2. Иконка уведомлений

Создайте иконку `ic_stat_notification.png` в `android/app/src/main/res/drawable/`

### iOS

#### 1. AppDelegate.swift

Минимальная настройка (инициализация происходит через React Native):

```swift
import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase инициализация
        FirebaseApp.configure()

        // AppMetrica Push SDK инициализируется через React Native
        return true
    }
}
```

#### 2. Info.plist

Добавьте разрешения для push уведомлений:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Использование в React Native

### ⚠️ Важно: Порядок инициализации

**AppMetrica Push SDK должен инициализироваться ТОЛЬКО после активации основной AppMetrica!**

```typescript
import { AppMetrica } from "@appmetrica/react-native-analytics";

// 1. Сначала активируем основную AppMetrica
AppMetrica.activate({
  apiKey: "YOUR_APPMETRICA_API_KEY",
});

// 2. ТОЛЬКО ПОСЛЕ этого инициализируем Push SDK
await AppMetricaPush.initialize({
  debugMode: __DEV__,
  apnsToken: Platform.OS === "ios" ? apnsToken : undefined,
});
```

### 1. Базовый пример

```typescript
import { Platform } from "react-native";
import { getAPNSToken, getMessaging } from "@react-native-firebase/messaging";
import { AppMetrica } from "@appmetrica/react-native-analytics";
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

const initializeAppMetricaWithPush = async () => {
  try {
    // 1. Активация основной AppMetrica
    AppMetrica.activate({
      apiKey: "YOUR_APPMETRICA_API_KEY",
    });

    console.log("AppMetrica activated");

    // 2. Получение APNS токена для iOS
    let apnsToken = "";
    if (Platform.OS === "ios") {
      const messaging = getMessaging();
      apnsToken = (await getAPNSToken(messaging)) ?? "";

      if (!apnsToken) {
        console.error("Failed to get APNS token for iOS");
        return;
      }
    }

    // 3. Инициализация AppMetrica Push SDK (ТОЛЬКО после AppMetrica.activate)
    const result = await AppMetricaPush.initialize({
      debugMode: __DEV__,
      apnsToken: Platform.OS === "ios" ? apnsToken : undefined,
    });

    if (result.success) {
      console.log("AppMetrica Push SDK initialized successfully");
    } else {
      console.error("Failed to initialize AppMetrica Push SDK:", result.error);
    }
  } catch (error) {
    console.error("Error initializing AppMetrica Push SDK:", error);
  }
};
```

### 2. Обработка push уведомлений

```typescript
import messaging from "@react-native-firebase/messaging";
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

// Обработка уведомлений в foreground
const unsubscribe = messaging().onMessage(async (remoteMessage) => {
  console.log("A new FCM message arrived!", remoteMessage);

  // Проверяем, что уведомление от AppMetrica
  const isFromAppMetrica = await AppMetricaPush.isNotificationFromAppMetrica(
    remoteMessage
  );

  if (isFromAppMetrica) {
    // Получаем пользовательские данные
    const userData = await AppMetricaPush.getUserData(remoteMessage);
    console.log("AppMetrica user data:", userData);

    // Показываем уведомление
    // ... ваш код для отображения уведомления
  }
});

// Обработка уведомлений при открытии приложения
messaging().onNotificationOpenedApp((remoteMessage) => {
  console.log(
    "Notification caused app to open from background state:",
    remoteMessage
  );

  // Проверяем, что уведомление от AppMetrica
  AppMetricaPush.isNotificationFromAppMetrica(remoteMessage).then(
    (isFromAppMetrica) => {
      if (isFromAppMetrica) {
        // Обрабатываем открытие уведомления
        // ... ваш код навигации
      }
    }
  );
});
```

### 3. Использование React Hook

```typescript
import React from "react";
import { View, Text } from "react-native";
import { useAppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

const MyComponent = () => {
  const { sdkInfo, isInitialized, isLoading } = useAppMetricaPush();

  if (isLoading) {
    return <Text>Loading...</Text>;
  }

  return (
    <View>
      <Text>SDK initialized: {isInitialized ? "Yes" : "No"}</Text>
      {sdkInfo && <Text>Version: {sdkInfo.version}</Text>}
    </View>
  );
};
```

## API Reference

### Основные методы

#### `initialize(config: PushConfig): Promise<InitializationResult>`

Инициализация AppMetrica Push SDK.

**Параметры:**

- `config.debugMode?: boolean` - режим отладки
- `config.apnsToken?: string` - APNS токен для iOS (обязательно)
- `config.appGroup?: string` - App Group для iOS расширений

**Возвращает:**

```typescript
{
  success: boolean;
  error?: string;
}
```

#### `isNotificationFromAppMetrica(notification: any): Promise<boolean>`

Проверяет, что уведомление отправлено через AppMetrica.

**Параметры:**

- `notification` - объект уведомления

**Возвращает:** `boolean`

#### `getUserData(notification: any): Promise<any>`

Извлекает пользовательские данные из уведомления AppMetrica.

**Параметры:**

- `notification` - объект уведомления

**Возвращает:** объект с пользовательскими данными

#### `getSDKInfo(): Promise<SDKInfo | null>`

Получает информацию о SDK.

**Возвращает:**

```typescript
{
  version: string;
  platform: string;
  sdkName?: string;
  libraryVersion?: string;
}
```

### Утилиты

#### `initializeAppMetricaPush(config: PushConfig, forceReinit?: boolean): Promise<boolean>`

Инициализация с дополнительными проверками.

#### `isSDKInitialized(): boolean`

Проверяет, инициализирован ли SDK.

#### `getCurrentConfig(): PushConfig | null`

Получает текущую конфигурацию.

#### `registerDeviceToken(deviceToken: string): Promise<boolean>`

Регистрирует device token.

### React Hook

#### `useAppMetricaPush(): UseAppMetricaPushReturn`

Хук для работы с SDK в React компонентах.

**Возвращает:**

```typescript
{
  sdkInfo: SDKInfo | null;
  isInitialized: boolean;
  isLoading: boolean;
  refreshSDKInfo: () => Promise<void>;
}
```

## Примеры использования

### 1. Полная инициализация

```typescript
import { useEffect } from "react";
import { Platform } from "react-native";
import { getAPNSToken, getMessaging } from "@react-native-firebase/messaging";
import { AppMetrica } from "@appmetrica/react-native-analytics";
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

export const useAppMetricaPushInit = () => {
  useEffect(() => {
    const init = async () => {
      try {
        // 1. Активация основной AppMetrica (ОБЯЗАТЕЛЬНО ПЕРВЫМ!)
        AppMetrica.activate({
          apiKey: "YOUR_APPMETRICA_API_KEY",
        });

        console.log("AppMetrica activated");

        // 2. Получение разрешений на push уведомления
        const authStatus = await messaging().requestPermission();
        const enabled =
          authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
          authStatus === messaging.AuthorizationStatus.PROVISIONAL;

        if (!enabled) {
          console.log("Push notifications not authorized");
          return;
        }

        // 3. Получение APNS токена для iOS
        let apnsToken = "";
        if (Platform.OS === "ios") {
          const messagingInstance = getMessaging();
          apnsToken = (await getAPNSToken(messagingInstance)) ?? "";
        }

        // 4. Инициализация AppMetrica Push SDK (ТОЛЬКО после AppMetrica.activate)
        const result = await AppMetricaPush.initialize({
          debugMode: __DEV__,
          apnsToken: Platform.OS === "ios" ? apnsToken : undefined,
        });

        if (result.success) {
          console.log("AppMetrica Push SDK initialized");
        }
      } catch (error) {
        console.error("Failed to initialize AppMetrica Push SDK:", error);
      }
    };

    init();
  }, []);
};
```

### 2. Обработка уведомлений с навигацией

```typescript
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";
import { NavigationContainerRef } from "@react-navigation/native";

const handleNotificationPress = async (notification: any) => {
  const isFromAppMetrica = await AppMetricaPush.isNotificationFromAppMetrica(
    notification
  );

  if (isFromAppMetrica) {
    const userData = await AppMetricaPush.getUserData(notification);

    // Навигация на основе данных уведомления
    if (userData?.screen) {
      navigationRef.current?.navigate(userData.screen, userData.params);
    }
  }
};
```

### 3. Отслеживание событий

```typescript
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

const trackPushEvent = async (notification: any, action: string) => {
  const isFromAppMetrica = await AppMetricaPush.isNotificationFromAppMetrica(
    notification
  );

  if (isFromAppMetrica) {
    const userData = await AppMetricaPush.getUserData(notification);

    // Отправка события в аналитику
    analytics.track("push_notification_action", {
      action,
      campaign_id: userData?.campaign_id,
      message_id: userData?.message_id,
    });
  }
};
```

## Troubleshooting

### Частые проблемы

#### 1. "AppMetricaPushModule is not available"

**Причины:**

- Библиотека не установлена
- Не выполнена линковка (iOS)
- Не пересобран проект

**Решение:**

```bash
# Переустановка
npm uninstall @suro4ek/appmetrica-push-sdk
npm install @suro4ek/appmetrica-push-sdk

# iOS
cd ios && pod install

# Пересборка
npx react-native run-ios
npx react-native run-android
```

#### 2. Push-уведомления не приходят

**Проверьте:**

1. **Порядок инициализации:**

   ```typescript
   // ❌ НЕПРАВИЛЬНО - Push SDK инициализируется до AppMetrica
   await AppMetricaPush.initialize(config);
   AppMetrica.activate({ apiKey: "YOUR_KEY" });

   // ✅ ПРАВИЛЬНО - сначала AppMetrica, потом Push SDK
   AppMetrica.activate({ apiKey: "YOUR_KEY" });
   await AppMetricaPush.initialize(config);
   ```

2. **Firebase настройки:**

   - `google-services.json` в `android/app/`
   - `GoogleService-Info.plist` в iOS проекте

3. **Разрешения:**

   ```typescript
   const authStatus = await messaging().requestPermission();
   console.log("Authorization status:", authStatus);
   ```

4. **APNS токен (iOS):**

   ```typescript
   const apnsToken = await getAPNSToken(getMessaging());
   console.log("APNS token:", apnsToken);
   ```

5. **Логи:**

   ```bash
   # Android
   npx react-native log-android

   # iOS
   npx react-native log-ios
   ```

#### 3. Ошибки компиляции

**Решение:**

```bash
# Очистка кэша
npx react-native start --reset-cache

# Очистка build
cd android && ./gradlew clean
cd ios && xcodebuild clean

# Пересборка
npx react-native run-android
npx react-native run-ios
```

#### 4. Silent Push не работает

**Проверьте AndroidManifest.xml:**

```xml
<receiver android:name="com.appmetricapush.SilentPushReceiver"
          android:exported="false">
    <intent-filter>
        <action android:name="com.appmetricapush.action.ymp.SILENT_PUSH_RECEIVE"/>
    </intent-filter>
</receiver>
```

#### 5. Уведомления без звука

**Для Android:** Убедитесь, что в AppMetrica указан канал `appmetrica_push_channel`

**Для iOS:** Проверьте настройки APNS сертификатов

### Отладка

#### Включение debug режима

```typescript
await AppMetricaPush.initialize({
  debugMode: true, // Включает подробные логи
  apnsToken: apnsToken,
});
```

#### Проверка статуса SDK

```typescript
const isInitialized = AppMetricaPush.isSDKInitialized();
const config = AppMetricaPush.getConfig();
const sdkInfo = await AppMetricaPush.getSDKInfo();

console.log("SDK Status:", { isInitialized, config, sdkInfo });
```

### Поддержка

- **GitHub Issues:** [suro4ek/appmetrica-push-sdk](https://github.com/suro4ek/appmetrica-push-sdk/issues)
- **AppMetrica Docs:** [Push SDK Documentation](https://appmetrica.yandex.ru/docs/mobile-sdk-dg/push-sdk/about.html)
- **Firebase Docs:** [React Native Firebase](https://rnfirebase.io/)
