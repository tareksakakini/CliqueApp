package com.clique.app.core.notifications

import android.content.Context
import com.clique.app.BuildConfig
import com.clique.app.R
import com.onesignal.OneSignal
import com.onesignal.debug.LogLevel
import com.onesignal.notifications.INotificationClickEvent
import com.onesignal.notifications.INotificationClickListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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
        val appId = context.getString(R.string.onesignal_app_id)
        if (appId.isBlank() || appId.contains("CHANGE_ME")) {
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
        val appId = context.getString(R.string.onesignal_app_id)
        if (restApiKey.isBlank() || restApiKey.contains("REPLACE") || appId.isBlank()) {
            return
        }
        val payload = JSONObject().apply {
            put("app_id", appId)
            put("include_external_user_ids", listOf(receiverUid))
            put("contents", mapOf("en" to message))
            title?.let { put("headings", mapOf("en" to it)) }
            route?.let {
                val data = JSONObject()
                data.put("route", JSONObject(it))
                data.put("receiverId", receiverUid)
                put("data", data)
            }
            put("mutable_content", true)
        }
        withContext(Dispatchers.IO) {
            val url = URL("https://onesignal.com/api/v1/notifications")
            (url.openConnection() as? HttpURLConnection)?.run {
                requestMethod = "POST"
                setRequestProperty("Authorization", "Basic $restApiKey")
                setRequestProperty("Content-Type", "application/json")
                doOutput = true
                outputStream.use { it.write(payload.toString().toByteArray()) }
                val responseCode = responseCode
                if (responseCode !in 200..299) {
                    errorStream?.bufferedReader()?.use { println(it.readText()) }
                }
                disconnect()
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
