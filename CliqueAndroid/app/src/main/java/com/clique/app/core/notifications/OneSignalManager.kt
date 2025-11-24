package com.clique.app.core.notifications

import android.content.Context
import com.clique.app.BuildConfig
import com.onesignal.OneSignal
import com.onesignal.debug.LogLevel
import com.onesignal.notifications.INotificationClickEvent
import com.onesignal.notifications.INotificationClickListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class OneSignalManager(
    private val context: Context,
    private val router: NotificationRouter
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var initialized = false

    fun initialize() {
        val appId = BuildConfig.ONESIGNAL_APP_ID
        if (appId.isBlank() || appId.contains("REPLACE")) {
            return
        }
        OneSignal.initWithContext(context, appId)
        OneSignal.Debug.logLevel = LogLevel.VERBOSE
        initialized = true
        scope.launch {
            OneSignal.Notifications.requestPermission(fallbackToSettings = false)
        }
        OneSignal.Notifications.addClickListener(object : INotificationClickListener {
            override fun onClick(event: INotificationClickEvent) {
                val additionalData = event.notification.additionalData?.toMap() ?: emptyMap()
                router.handlePayload(additionalData)
            }
        })
    }

    suspend fun login(userId: String) {
        if (!initialized) return
        withContext(Dispatchers.IO) {
            OneSignal.login(userId)
        }
    }

    suspend fun logout() {
        if (!initialized) return
        withContext(Dispatchers.IO) {
            OneSignal.logout()
        }
    }

    fun isConfiguredFor(userId: String): Boolean = OneSignal.User.externalId == userId

    suspend fun sendPushNotification(
        message: String,
        receiverUid: String,
        route: Map<String, Any?>? = null,
        title: String? = null
    ) {
        val restApiKey = BuildConfig.ONESIGNAL_REST_KEY
        val appId = BuildConfig.ONESIGNAL_APP_ID
        if (restApiKey.isBlank() || restApiKey.contains("REPLACE") || appId.isBlank() || appId.contains("REPLACE")) {
            android.util.Log.e("OneSignalManager", "❌ Cannot send notification: OneSignal not configured (API key or App ID missing or placeholder)")
            return
        }
        
        android.util.Log.d("OneSignalManager", "📤 Sending notification:")
        android.util.Log.d("OneSignalManager", "   Receiver UID: $receiverUid")
        android.util.Log.d("OneSignalManager", "   Message: $message")
        android.util.Log.d("OneSignalManager", "   Title: ${title ?: "Yalla"}")
        android.util.Log.d("OneSignalManager", "   Route: $route")
        
        val payload = JSONObject().apply {
            put("app_id", appId)
            put("include_external_user_ids", JSONArray().apply {
                put(receiverUid)
            })
            put("contents", JSONObject().apply {
                put("en", message)
            })
            title?.let { 
                put("headings", JSONObject().apply {
                    put("en", it)
                })
            }
            if (route != null) {
                val data = JSONObject()
                val routeJson = JSONObject()
                route.forEach { (key, value) ->
                    when (value) {
                        is String -> routeJson.put(key, value)
                        is Boolean -> routeJson.put(key, value)
                        is Number -> routeJson.put(key, value)
                        null -> routeJson.put(key, JSONObject.NULL)
                        else -> routeJson.put(key, value.toString())
                    }
                }
                data.put("route", routeJson)
                data.put("receiverId", receiverUid)
                put("data", data)
                android.util.Log.d("OneSignalManager", "   Route JSON: ${routeJson.toString(2)}")
            } else {
                // Even without route, add receiverId to data
                val data = JSONObject()
                data.put("receiverId", receiverUid)
                put("data", data)
            }
            put("mutable_content", true)
        }
        
        android.util.Log.d("OneSignalManager", "📦 Notification payload: ${payload.toString(2)}")
        
        withContext(Dispatchers.IO) {
            try {
                val url = URL("https://onesignal.com/api/v1/notifications")
                (url.openConnection() as? HttpURLConnection)?.run {
                    requestMethod = "POST"
                    setRequestProperty("Authorization", "Basic $restApiKey")
                    setRequestProperty("Content-Type", "application/json")
                    doOutput = true
                    outputStream.use { it.write(payload.toString().toByteArray()) }
                    val responseCode = responseCode
                    if (responseCode in 200..299) {
                        android.util.Log.d("OneSignalManager", "✅ Notification sent successfully (HTTP $responseCode)")
                        inputStream?.bufferedReader()?.use { reader ->
                            val response = reader.readText()
                            android.util.Log.d("OneSignalManager", "📡 OneSignal response: $response")
                        }
                    } else {
                        android.util.Log.e("OneSignalManager", "❌ Failed to send notification (HTTP $responseCode)")
                        errorStream?.bufferedReader()?.use { reader ->
                            val errorResponse = reader.readText()
                            android.util.Log.e("OneSignalManager", "❌ Error response: $errorResponse")
                        }
                    }
                    disconnect()
                }
            } catch (e: Exception) {
                android.util.Log.e("OneSignalManager", "❌ Exception sending notification: ${e.message}", e)
            }
        }
    }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        keys().forEach { key ->
            map[key] = when (val value = get(key)) {
                is JSONObject -> value.toMap()
                else -> value
            }
        }
        return map
    }
}
