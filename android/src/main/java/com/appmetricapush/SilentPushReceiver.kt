package com.appmetricapush

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.appmetrica.analytics.push.AppMetricaPush

/**
 * Receiver для обработки silent push уведомлений от AppMetrica
 * Настроен согласно документации AppMetrica Push SDK
 * Входит в состав библиотеки @suro4ek/appmetrica-push-sdk
 */
class SilentPushReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AppMetricaSilentPushReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        try {
            // Extract push message payload from your push message.
            val payload = intent.getStringExtra(AppMetricaPush.EXTRA_PAYLOAD)
            
            if (payload != null) {
                Log.d(TAG, "Silent push received with payload: $payload")
                
                // AppMetrica Push SDK автоматически обрабатывает silent push
                // Здесь можно добавить дополнительную логику обработки
                handleSilentPushPayload(context, payload)
            } else {
                Log.w(TAG, "Silent push received but payload is null")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling silent push", e)
        }
    }

    /**
     * Обработка payload от silent push
     */
    private fun handleSilentPushPayload(context: Context, payload: String) {
        try {
            // Логируем получение silent push
            Log.d(TAG, "Processing silent push payload: $payload")
            
            // AppMetrica Push SDK автоматически обрабатывает silent push
            // Здесь можно добавить дополнительную логику обработки
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing silent push payload", e)
        }
    }
}
