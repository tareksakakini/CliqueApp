package com.yallaconnect.app.core.notifications

object NotificationRouteBuilder {
    private enum class Screen(val raw: String) {
        EVENT_DETAIL("event_detail"),
        TAB("tab"),
        FRIENDS("friend_requests")
    }

    fun eventDetail(
        eventId: String,
        inviteView: Boolean,
        preferredTab: NotificationRouter.NotificationTab?,
        openChat: Boolean = false
    ): Map<String, Any?> {
        val route = mutableMapOf<String, Any?>(
            NotificationRouter.Key.SCREEN to Screen.EVENT_DETAIL.raw,
            NotificationRouter.Key.EVENT_ID to eventId,
            NotificationRouter.Key.INVITE_VIEW to inviteView
        )
        preferredTab?.let {
            route[NotificationRouter.Key.TAB] = it.name
        }
        if (openChat) {
            route[NotificationRouter.Key.OPEN_CHAT] = true
        }
        return route
    }

    fun friends(section: NotificationRouter.FriendSectionShortcut): Map<String, Any?> {
        return mapOf(
            NotificationRouter.Key.SCREEN to Screen.FRIENDS.raw,
            NotificationRouter.Key.SECTION to section.name,
            NotificationRouter.Key.TAB to NotificationRouter.NotificationTab.FRIENDS.name
        )
    }

    fun tab(tab: NotificationRouter.NotificationTab): Map<String, Any?> {
        return mapOf(
            NotificationRouter.Key.SCREEN to Screen.TAB.raw,
            NotificationRouter.Key.TAB to tab.name
        )
    }
}





