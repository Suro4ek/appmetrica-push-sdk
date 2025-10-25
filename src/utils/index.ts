import AppMetricaPush from "../AppMetricaPushModule";
import { PushConfig } from "../types";

/**
 * Инициализация AppMetrica Push SDK с проверками
 */
export const initializeAppMetricaPush = async (
  config: PushConfig,
  forceReinit = false
): Promise<boolean> => {
  const instance = AppMetricaPush.getInstance();

  if (instance.isSDKInitialized() && !forceReinit) {
    console.warn("AppMetrica Push SDK is already initialized");
    return true;
  }

  const result = await instance.initialize(config);
  return result.success;
};

/**
 * Проверка, что уведомление от AppMetrica
 * Используется в собственных сервисах обработки push уведомлений
 */
export const isNotificationFromAppMetrica = async (
  notification: any
): Promise<boolean> => {
  const instance = AppMetricaPush.getInstance();

  if (!instance.isSDKInitialized()) {
    console.error("AppMetrica Push SDK is not initialized");
    return false;
  }

  try {
    return await instance.isNotificationFromAppMetrica(notification);
  } catch (error) {
    console.error("Failed to check if notification is from AppMetrica:", error);
    return false;
  }
};

/**
 * Получение информации о SDK
 */
export const getPushSDKInfo = async () => {
  const instance = AppMetricaPush.getInstance();

  try {
    return await instance.getSDKInfo();
  } catch (error) {
    console.error("Failed to get SDK info:", error);
    return null;
  }
};

/**
 * Получение дополнительной информации из push-уведомления
 * Согласно документации AppMetrica Push SDK
 */
export const getUserDataFromNotification = async (notification: any) => {
  const instance = AppMetricaPush.getInstance();

  if (!instance.isSDKInitialized()) {
    console.error("AppMetrica Push SDK is not initialized");
    return null;
  }

  try {
    return await instance.getUserData(notification);
  } catch (error) {
    console.error("Failed to get user data from notification:", error);
    return null;
  }
};

/**
 * Проверка инициализации SDK
 */
export const isSDKInitialized = (): boolean => {
  const instance = AppMetricaPush.getInstance();
  return instance.isSDKInitialized();
};

/**
 * Получение текущей конфигурации
 */
export const getCurrentConfig = () => {
  const instance = AppMetricaPush.getInstance();
  return instance.getConfig();
};

/**
 * Сброс состояния SDK (для тестирования)
 */
export const resetSDK = (): void => {
  const instance = AppMetricaPush.getInstance();
  instance.reset();
};
