// Основной класс
export { default as AppMetricaPush } from "./AppMetricaPushModule";

// Хуки
export { useAppMetricaPush } from "./hooks/useAppMetricaPush";
export type { UseAppMetricaPushReturn } from "./hooks/useAppMetricaPush";

// Утилиты
export {
  initializeAppMetricaPush,
  isNotificationFromAppMetrica,
  getPushSDKInfo,
  getUserDataFromNotification,
  isSDKInitialized,
  getCurrentConfig,
  resetSDK,
} from "./utils";

// Типы
export type { PushConfig, SDKInfo, InitializationResult } from "./types";

// Версия библиотеки
export const VERSION = "1.0.0";
