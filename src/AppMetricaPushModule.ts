import { NativeModules, Platform } from "react-native";
import { PushConfig, SDKInfo, InitializationResult } from "./types";

const { AppMetricaPushModule } = NativeModules;

/**
 * Основной класс для работы с AppMetrica Push SDK
 */
class AppMetricaPush {
  private static instance: AppMetricaPush | null = null;
  private isInitialized = false;
  private config: PushConfig | null = null;

  /**
   * Получить экземпляр класса (Singleton)
   */
  static getInstance(): AppMetricaPush {
    if (!AppMetricaPush.instance) {
      AppMetricaPush.instance = new AppMetricaPush();
    }
    return AppMetricaPush.instance;
  }

  /**
   * Инициализация AppMetrica Push SDK
   */
  async initialize(config: PushConfig): Promise<InitializationResult> {
    try {
      if (!AppMetricaPushModule) {
        throw new Error(
          "AppMetricaPushModule is not available. Make sure the native module is properly linked."
        );
      }

      if (this.isInitialized) {
        console.warn("AppMetrica Push SDK is already initialized");
        return { success: true };
      }

      const result = await AppMetricaPushModule.initialize(config);

      if (result) {
        this.isInitialized = true;
        this.config = config;

        if (config.debugMode) {
          console.log("AppMetrica Push SDK initialized successfully");
        }

        return { success: true };
      } else {
        return {
          success: false,
          error: "Failed to initialize AppMetrica Push SDK",
        };
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error";
      console.error("AppMetrica Push initialization failed:", errorMessage);
      return { success: false, error: errorMessage };
    }
  }

  /**
   * Проверка, что уведомление от AppMetrica
   * Используется в собственных сервисах обработки push уведомлений
   */
  async isNotificationFromAppMetrica(notification: any): Promise<boolean> {
    try {
      if (!AppMetricaPushModule) {
        return false;
      }

      // Проверяем наличие метода в нативном модуле
      if (
        typeof AppMetricaPushModule.isNotificationFromAppMetrica === "function"
      ) {
        return await AppMetricaPushModule.isNotificationFromAppMetrica(
          notification
        );
      } else {
        // Fallback для iOS - проверяем поля вручную
        if (Platform.OS === "ios") {
          const data = notification?.data || notification?.aps?.data;
          return !!(
            data?.ym_push_id ||
            data?.ym_campaign_id ||
            data?.ym_message_id
          );
        }
        return false;
      }
    } catch (error) {
      console.error(
        "Failed to check if notification is from AppMetrica:",
        error
      );
      return false;
    }
  }

  /**
   * Получение информации о SDK
   */
  async getSDKInfo(): Promise<SDKInfo | null> {
    try {
      if (!AppMetricaPushModule) {
        return null;
      }

      return await AppMetricaPushModule.getSDKInfo();
    } catch (error) {
      console.error("Failed to get SDK info:", error);
      return null;
    }
  }

  /**
   * Получение дополнительной информации из push-уведомления
   * Согласно документации AppMetrica Push SDK
   */
  async getUserData(notification: any): Promise<any> {
    try {
      if (!AppMetricaPushModule) {
        return null;
      }

      return await AppMetricaPushModule.getUserData(notification);
    } catch (error) {
      console.error("Failed to get user data:", error);
      return null;
    }
  }

  /**
   * Проверка инициализации
   */
  isSDKInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * Получение текущей конфигурации
   */
  getConfig(): PushConfig | null {
    return this.config;
  }

  /**
   * Сброс состояния (для тестирования)
   */
  reset(): void {
    this.isInitialized = false;
    this.config = null;
  }
}

export default AppMetricaPush;
