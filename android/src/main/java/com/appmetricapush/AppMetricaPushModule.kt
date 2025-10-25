package com.appmetricapush

import android.util.Log
import androidx.annotation.NonNull
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments
import io.appmetrica.analytics.push.AppMetricaPush

/**
 * React Native модуль для AppMetrica Push SDK
 * Написан на Kotlin для лучшей интеграции с современным Android разработкой
 */
class AppMetricaPushModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    
    companion object {
        private const val MODULE_NAME = "AppMetricaPushModule"
        private const val TAG = "AppMetricaPush"
    }

    @NonNull
    override fun getName(): String {
        return MODULE_NAME
    }

    @ReactMethod
    fun initialize(config: ReadableMap, promise: Promise) {
        try {
            val debugMode = if (config.hasKey("debugMode")) config.getBoolean("debugMode") else false

            // Инициализация AppMetrica Push
            AppMetricaPush.activate(reactApplicationContext)
            
            // Настройка дефолтного канала AppMetrica Push SDK
            setupAppMetricaDefaultChannel()
            
            if (debugMode) {
                Log.d(TAG, "AppMetrica Push initialized successfully")
            }

            promise.resolve(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize AppMetrica Push", e)
            promise.reject("INIT_ERROR", e.message)
        }
    }


    /**
     * Настройка дефолтного канала AppMetrica Push SDK
     */
    private fun setupAppMetricaDefaultChannel() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                // Получаем дефолтный канал AppMetrica и настраиваем его
                // appmetrica_push_channel
                AppMetricaPush.getDefaultNotificationChannel()?.apply {
                    description = "Push notifications from AppMetrica"
                    importance = android.app.NotificationManager.IMPORTANCE_HIGH
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                    // Включаем звук
                    setSound(android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION), null)
                }
                Log.d(TAG, "AppMetrica default notification channel configured with sound")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup AppMetrica default channel", e)
        }
    }


    @ReactMethod
    fun isNotificationFromAppMetrica(notification: ReadableMap, promise: Promise) {
        try {
            // Проверяем, что push уведомление не от AppMetrica
            // Это нужно для собственных сервисов обработки push уведомлений
            var isFromAppMetrica = false
            
            if (notification.hasKey("data")) {
                // Проверяем наличие специфических полей AppMetrica в данных
                val data = notification.getString("data")
                if (data != null && data.contains("appmetrica")) {
                    isFromAppMetrica = true
                }
            }
            
            promise.resolve(isFromAppMetrica)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check if notification is from AppMetrica", e)
            promise.reject("NOTIFICATION_CHECK_ERROR", e.message)
        }
    }

    @ReactMethod
    fun getSDKInfo(promise: Promise) {
        try {
            val info = Arguments.createMap().apply {
                // Получаем актуальную версию AppMetrica Push SDK
                putString("version", getAppMetricaPushVersion())
                putString("platform", "android")
                putString("sdkName", "AppMetrica Push SDK")
                putString("libraryVersion", "1.0.0") // Версия нашей библиотеки
            }
            promise.resolve(info)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get SDK info", e)
            promise.reject("SDK_INFO_ERROR", e.message)
        }
    }

    @ReactMethod
    fun getUserData(notification: ReadableMap, promise: Promise) {
        try {
            // Получаем дополнительную информацию из push-уведомления согласно документации
            // AppMetrica Push SDK автоматически извлекает userData из уведомления
            val userData = Arguments.createMap()
            
            // Проверяем наличие данных в уведомлении
            if (notification.hasKey("data")) {
                val data = notification.getMap("data")
                if (data != null) {
                    // Копируем все данные из notification.data в userData
                    val iterator = data.entryIterator
                    while (iterator.hasNextKey()) {
                        val key = iterator.nextKey()
                        val value = data.getDynamic(key)
                        userData.putDynamic(key, value)
                    }
                }
            }
            
            promise.resolve(userData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get user data from notification", e)
            promise.reject("USER_DATA_ERROR", e.message)
        }
    }

    /**
     * Получение версии AppMetrica Push SDK
     */
    private fun getAppMetricaPushVersion(): String {
        return try {
            // Пытаемся получить версию из AppMetrica Push SDK
            val version = io.appmetrica.analytics.push.BuildConfig.VERSION_NAME
            version ?: "4.2.1" // Fallback версия
        } catch (e: Exception) {
            Log.w(TAG, "Could not get AppMetrica Push version, using fallback", e)
            "4.2.1" // Fallback версия
        }
    }
}
