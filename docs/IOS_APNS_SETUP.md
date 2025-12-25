# Настройка APNS токена для iOS

## Обязательные требования

Для корректной работы AppMetrica Push SDK на iOS **обязательно** необходимо передавать APNS токен при инициализации.

## Установка зависимостей

```bash
npm install @react-native-firebase/messaging
```

## Получение APNS токена

```typescript
import { Platform } from "react-native";
import { getAPNSToken, getMessaging } from "@react-native-firebase/messaging";

// Получение APNS токена для iOS
let apnsToken = "";
if (Platform.OS === "ios") {
  const messaging = getMessaging();
  apnsToken = (await getAPNSToken(messaging)) ?? "";
}
```

## Инициализация с APNS токеном

```typescript
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

await AppMetricaPush.initialize({
  debugMode: __DEV__,
  apnsToken: Platform.OS === "ios" ? apnsToken : undefined,
});
```

## Полный пример

```typescript
import { Platform } from "react-native";
import { getAPNSToken, getMessaging } from "@react-native-firebase/messaging";
import { AppMetricaPush } from "@suro4ek/appmetrica-push-sdk";

const initializeAppMetricaPush = async () => {
  try {
    // Получение APNS токена для iOS
    let apnsToken = "";
    if (Platform.OS === "ios") {
      const messaging = getMessaging();
      apnsToken = (await getAPNSToken(messaging)) ?? "";

      if (!apnsToken) {
        console.error("Failed to get APNS token for iOS");
        return;
      }
    }

    // Инициализация AppMetrica Push SDK
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

## Важные моменты

1. **APNS токен обязателен для iOS** - без него push уведомления не будут работать
2. **Android не требует APNS токен** - для Android используется Firebase Cloud Messaging
3. **Токен получается асинхронно** - используйте `await` при получении токена
4. **Проверяйте наличие токена** - убедитесь, что токен получен перед инициализацией

## Troubleshooting

### APNS токен не получается

1. Убедитесь, что Firebase настроен правильно
2. Проверьте, что приложение имеет разрешения на push уведомления
3. Убедитесь, что используется правильный bundle ID в Firebase консоли

### Push уведомления не приходят на iOS

1. Проверьте, что APNS токен передается при инициализации
2. Убедитесь, что сертификаты APNS настроены правильно
3. Проверьте, что AppMetrica Push SDK инициализирован успешно
