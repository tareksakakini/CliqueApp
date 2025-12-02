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
        android.util.Log.d("OneSignalManager", "🔧 Initializing OneSignal...")
        android.util.Log.d("OneSignalManager", "   App ID: ${if (appId.isBlank()) "BLANK" else if (appId.contains("REPLACE")) "PLACEHOLDER" else appId.take(8) + "..."}")
        
        if (appId.isBlank() || appId.contains("REPLACE")) {
            android.util.Log.e("OneSignalManager", "❌ OneSignal not initialized: App ID is blank or placeholder")
            android.util.Log.e("OneSignalManager", "   Please configure ONESIGNAL_APP_ID in local.properties")
            return
        }
        
        try {
            OneSignal.initWithContext(context, appId)
            OneSignal.Debug.logLevel = LogLevel.VERBOSE
            initialized = true
            android.util.Log.d("OneSignalManager", "✅ OneSignal initialized successfully")
            
            scope.launch {
                try {
                    val permissionGranted = OneSignal.Notifications.requestPermission(fallbackToSettings = false)
                    android.util.Log.d("OneSignalManager", "   Notification permission: ${if (permissionGranted) "GRANTED" else "DENIED"}")
                } catch (e: Exception) {
                    android.util.Log.e("OneSignalManager", "❌ Error requesting notification permission: ${e.message}")
                }
            }
            
            OneSignal.Notifications.addClickListener(object : INotificationClickListener {
                override fun onClick(event: INotificationClickEvent) {
                    val additionalData = event.notification.additionalData?.toMap() ?: emptyMap()
                    android.util.Log.d("OneSignalManager", "🔔 Notification clicked: $additionalData")
                    router.handlePayload(additionalData)
                }
            })
        } catch (e: Exception) {
            android.util.Log.e("OneSignalManager", "❌ Error initializing OneSignal: ${e.message}", e)
            initialized = false
        }
    }

    suspend fun login(userId: String) {
        if (!initialized) {
            android.util.Log.e("OneSignalManager", "❌ Cannot login: OneSignal not initialized")
            return
        }
        if (userId.isBlank()) {
            android.util.Log.e("OneSignalManager", "❌ Cannot login: User ID is blank")
            return
        }
        android.util.Log.d("OneSignalManager", "🔐 Logging in user to OneSignal: $userId")
        withContext(Dispatchers.IO) {
            try {
                OneSignal.login(userId)
                // Verify login was successful
                val currentExternalId = OneSignal.User.externalId
                if (currentExternalId == userId) {
                    android.util.Log.d("OneSignalManager", "✅ Successfully logged in user to OneSignal: $userId")
                } else {
                    android.util.Log.w("OneSignalManager", "⚠️ Login called but external ID mismatch. Expected: $userId, Got: $currentExternalId")
                }
            } catch (e: Exception) {
                android.util.Log.e("OneSignalManager", "❌ Error logging in user to OneSignal: ${e.message}", e)
            }
        }
    }

    suspend fun logout() {
        if (!initialized) return
        withContext(Dispatchers.IO) {
            OneSignal.logout()
        }
    }

    fun isConfiguredFor(userId: String): Boolean = OneSignal.User.externalId == userId
    
    /**
     * Get current OneSignal status for debugging
     */
    fun getStatus(): Map<String, Any?> {
        return mapOf(
            "initialized" to initialized,
            "currentExternalId" to (try { OneSignal.User.externalId } catch (e: Exception) { "ERROR: ${e.message}" }),
            "appId" to (try { BuildConfig.ONESIGNAL_APP_ID.take(8) + "..." } catch (e: Exception) { "ERROR" }),
            "restKeyConfigured" to (try { 
                val key = BuildConfig.ONESIGNAL_REST_KEY
                !key.isBlank() && !key.contains("REPLACE")
            } catch (e: Exception) { false })
        )
    }

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
            android.util.Log.e("OneSignalManager", "   App ID: ${if (appId.isBlank()) "BLANK" else if (appId.contains("REPLACE")) "PLACEHOLDER" else "SET"}")
            android.util.Log.e("OneSignalManager", "   REST Key: ${if (restApiKey.isBlank()) "BLANK" else if (restApiKey.contains("REPLACE")) "PLACEHOLDER" else "SET"}")
            return
        }
        
        if (receiverUid.isBlank()) {
            android.util.Log.e("OneSignalManager", "❌ Cannot send notification: Receiver UID is blank")
            return
        }
        
        android.util.Log.d("OneSignalManager", "📤 Sending notification:")
        android.util.Log.d("OneSignalManager", "   Receiver UID: $receiverUid")
        android.util.Log.d("OneSignalManager", "   Message: $message")
        android.util.Log.d("OneSignalManager", "   Title: ${title ?: "Yalla"}")
        android.util.Log.d("OneSignalManager", "   Route: $route")
        android.util.Log.d("OneSignalManager", "   OneSignal initialized: $initialized")
        
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
                            
                            // Parse response to check for errors
                            try {
                                val responseJson = JSONObject(response)
                                if (responseJson.has("errors")) {
                                    val errors = responseJson.optJSONArray("errors")
                                    if (errors != null && errors.length() > 0) {
                                        android.util.Log.e("OneSignalManager", "⚠️ OneSignal returned errors in response:")
                                        for (i in 0 until errors.length()) {
                                            android.util.Log.e("OneSignalManager", "   Error: ${errors.getString(i)}")
                                        }
                                    }
                                }
                                // Check if receiver was found
                                val recipients = responseJson.optInt("recipients", -1)
                                when {
                                    recipients == 0 -> {
                                        android.util.Log.w("OneSignalManager", "⚠️ Notification sent but no recipients found. Receiver may not be logged into OneSignal with external ID: $receiverUid")
                                        android.util.Log.w("OneSignalManager", "   The receiver needs to: 1) Have the app installed, 2) Be signed in, 3) Have OneSignal.login() called with their user ID")
                                    }
                                    recipients > 0 -> {
                                        android.util.Log.d("OneSignalManager", "✅ Notification delivered to $recipients recipient(s)")
                                    }
                                    else -> {
                                        // recipients < 0 means the field wasn't in the response
                                        android.util.Log.d("OneSignalManager", "📡 Notification response received (recipients count not available)")
                                    }
                                }
                            } catch (e: Exception) {
                                android.util.Log.d("OneSignalManager", "Could not parse response JSON: ${e.message}")
                            }
                        }
                    } else {
                        android.util.Log.e("OneSignalManager", "❌ Failed to send notification (HTTP $responseCode)")
                        errorStream?.bufferedReader()?.use { reader ->
                            val errorResponse = reader.readText()
                            android.util.Log.e("OneSignalManager", "❌ Error response: $errorResponse")
                            
                            // Common error codes
                            when (responseCode) {
                                400 -> android.util.Log.e("OneSignalManager", "   This usually means: Invalid payload or receiver not found")
                                401 -> android.util.Log.e("OneSignalManager", "   This usually means: Invalid REST API key")
                                404 -> android.util.Log.e("OneSignalManager", "   This usually means: App ID not found or receiver not registered with OneSignal")
                                else -> android.util.Log.e("OneSignalManager", "   HTTP error code: $responseCode")
                            }
                        }
                    }
                    disconnect()
                }
            } catch (e: Exception) {
                android.util.Log.e("OneSignalManager", "❌ Exception sending notification: ${e.message}", e)
                android.util.Log.e("OneSignalManager", "   Stack trace: ${e.stackTraceToString()}")
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
