package com.appmetricapush

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.appmetrica.analytics.push.provider.firebase.AppMetricaMessagingService

/**
 * Основной сервис для обработки Firebase Cloud Messaging
 * Интегрирован с AppMetrica Push SDK
 * Входит в состав библиотеки @moyka/appmetrica-push-sdk
 */
class FirebaseMessagingMainService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "AppMetricaFirebaseService"
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        
        Log.d(TAG, "Firebase message received: ${message.messageId}")
        
        // Проверяем, что push уведомление от AppMetrica
        if (AppMetricaMessagingService.isNotificationRelatedToSDK(message)) {
            Log.d(TAG, "Processing AppMetrica push notification")
            // AppMetrica Push SDK сам покажет уведомление пользователю
            AppMetricaMessagingService().processPush(this, message)
            return
        }

        // Обрабатываем собственные push уведомления
        Log.d(TAG, "Processing custom push notification")
        handleCustomPushMessage(message)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        Log.d(TAG, "New FCM token received: $token")
        
        // Отправляем токен в AppMetrica Push SDK
        AppMetricaMessagingService().processToken(this, token)
        
        // Отправляем токен в другие SDK или обрабатываем самостоятельно
        handleCustomToken(token)
    }

    /**
     * Обработка собственных push уведомлений
     */
    private fun handleCustomPushMessage(message: RemoteMessage) {
        try {
            Log.d(TAG, "Custom push data: ${message.data}")
            Log.d(TAG, "Custom push notification: ${message.notification}")
            
            // Здесь можно добавить логику обработки собственных push уведомлений
            // Например, отправить событие в React Native через EventEmitter
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling custom push message", e)
        }
    }


    /**
     * Обработка собственного токена
     */
    private fun handleCustomToken(token: String) {
        try {
            Log.d(TAG, "Handling custom token: $token")
            
            // Здесь можно отправить токен в другие SDK или на ваш сервер
            // Например, отправить событие в React Native через EventEmitter
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling custom token", e)
        }
    }
}
