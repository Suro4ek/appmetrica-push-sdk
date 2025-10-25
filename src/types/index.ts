/**
 * Конфигурация для инициализации AppMetrica Push SDK
 */
export interface PushConfig {
  /** Режим отладки */
  debugMode?: boolean;
}

/**
 * Информация о SDK
 */
export interface SDKInfo {
  /** Версия AppMetrica Push SDK */
  version: string;
  /** Платформа */
  platform: string;
  /** Название SDK */
  sdkName?: string;
  /** Версия нашей библиотеки */
  libraryVersion?: string;
}

/**
 * Результат инициализации
 */
export interface InitializationResult {
  /** Успешность инициализации */
  success: boolean;
  /** Сообщение об ошибке */
  error?: string;
}
