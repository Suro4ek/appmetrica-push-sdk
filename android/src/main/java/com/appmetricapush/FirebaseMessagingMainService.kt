package com.appmetricapush

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.appmetrica.analytics.push.provider.firebase.AppMetricaMessagingService
import io.invertase.firebase.common.ReactNativeFirebaseEventEmitter
import io.invertase.firebase.common.SharedUtils
import io.invertase.firebase.messaging.ReactNativeFirebaseMessagingSerializer

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
            AppMetricaMessagingService().processPush(this, message)
        }

        // Прокидываем ВСЕ сообщения в RN Firebase (для JS onMessage listener)
        forwardToReactNativeFirebase(message)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)

        Log.d(TAG, "New FCM token received: $token")

        // Отправляем токен в AppMetrica Push SDK
        AppMetricaMessagingService().processToken(this, token)

        // Прокидываем токен в RN Firebase
        try {
            val emitter = ReactNativeFirebaseEventEmitter.getSharedInstance()
            emitter.sendEvent(
                ReactNativeFirebaseMessagingSerializer.newTokenToTokenEvent(token)
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error forwarding token to RN Firebase", e)
        }
    }

    /**
     * Прокидывает сообщение в RN Firebase, чтобы JS onMessage listener сработал
     */
    private fun forwardToReactNativeFirebase(message: RemoteMessage) {
        try {
            if (SharedUtils.isAppInForeground(this)) {
                val emitter = ReactNativeFirebaseEventEmitter.getSharedInstance()
                emitter.sendEvent(
                    ReactNativeFirebaseMessagingSerializer.remoteMessageToEvent(message, false)
                )
                Log.d(TAG, "Forwarded message to RN Firebase (foreground)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error forwarding to RN Firebase", e)
        }
    }
}
