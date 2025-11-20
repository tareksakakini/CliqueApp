package com.clique.app.core.notifications

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class NotificationRouter {
    sealed interface Destination {
        data class EventDetail(
            val eventId: String,
            val inviteView: Boolean,
            val preferredTab: NotificationTab?,
            val openChat: Boolean
        ) : Destination

        data class Tab(val tab: NotificationTab) : Destination
        data class FriendSection(val section: FriendSectionShortcut) : Destination
    }

    enum class NotificationTab { MY_EVENTS, INVITES, NEW_EVENT, FRIENDS, SETTINGS }

    enum class FriendSectionShortcut { FRIENDS, REQUESTS, SENT }

    object Key {
        const val SCREEN = "screen"
        const val EVENT_ID = "eventId"
        const val INVITE_VIEW = "inviteView"
        const val TAB = "tab"
        const val SECTION = "section"
        const val ROUTE = "route"
        const val OPEN_CHAT = "openChat"
    }

    private enum class Screen(val raw: String) {
        EVENT_DETAIL("event_detail"),
        TAB("tab"),
        FRIENDS("friend_requests")
    }

    private val _pendingRoute = MutableStateFlow<Destination?>(null)
    val pendingRoute: StateFlow<Destination?> = _pendingRoute

    fun handlePayload(payload: Map<String, Any?>) {
        val route = extractRoute(payload) ?: return
        when (val destination = parse(route)) {
            null -> return
            else -> _pendingRoute.value = destination
        }
    }

    fun consumeRoute() {
        _pendingRoute.value = null
    }

    private fun parse(route: Map<String, Any?>): Destination? {
        val screen = route[Key.SCREEN] as? String ?: return null
        return when (screen) {
            Screen.EVENT_DETAIL.raw -> {
                val eventId = route[Key.EVENT_ID] as? String ?: return null
                val inviteView = route[Key.INVITE_VIEW].toBoolean()
                val tabRaw = route[Key.TAB] as? String
                val tab = tabRaw?.let { runCatching { NotificationTab.valueOf(it.uppercase()) }.getOrNull() }
                val openChat = route[Key.OPEN_CHAT].toBoolean()
                Destination.EventDetail(eventId, inviteView, tab, openChat)
            }
            Screen.FRIENDS.raw -> {
                val sectionRaw = route[Key.SECTION] as? String ?: FriendSectionShortcut.REQUESTS.name
                val section = runCatching { FriendSectionShortcut.valueOf(sectionRaw.uppercase()) }.getOrNull()
                    ?: FriendSectionShortcut.REQUESTS
                Destination.FriendSection(section)
            }
            Screen.TAB.raw -> {
                val tabRaw = route[Key.TAB] as? String ?: return null
                val tab = runCatching { NotificationTab.valueOf(tabRaw.uppercase()) }.getOrNull()
                    ?: return null
                Destination.Tab(tab)
            }
            else -> runCatching { NotificationTab.valueOf(screen.uppercase()) }.getOrNull()?.let {
                Destination.Tab(it)
            }
        }
    }

    private fun extractRoute(userInfo: Map<String, Any?>): Map<String, Any?>? {
        val custom = userInfo["custom"] as? Map<*, *>
        val additional = custom?.get("a") as? Map<*, *>
        val directRoute = additional?.get(Key.ROUTE) as? Map<*, *>
            ?: userInfo[Key.ROUTE] as? Map<*, *>
            ?: (userInfo["data"] as? Map<*, *>)?.get(Key.ROUTE) as? Map<*, *>
        return directRoute?.mapNotNull { (key, value) ->
            (key as? String)?.let { it to value }
        }?.toMap()
    }

    private fun Any?.toBoolean(): Boolean = when (this) {
        is Boolean -> this
        is Number -> this.toInt() != 0
        is String -> this.equals("true", ignoreCase = true)
        else -> false
    }
}
