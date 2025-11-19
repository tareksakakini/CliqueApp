package com.clique.app.ui.screens.main

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import com.clique.app.data.repository.model.FriendshipAction
import com.clique.app.data.repository.model.InviteAction
import com.clique.app.ui.screens.create.CreateEventScreen
import com.clique.app.ui.screens.events.EventsScreen
import com.clique.app.ui.screens.friends.FriendsScreen
import com.clique.app.ui.screens.settings.SettingsScreen
import com.clique.app.ui.state.SessionState

private enum class MainTab(val label: String) {
    EVENTS("Events"),
    INVITES("Invites"),
    CREATE("New Event"),
    FRIENDS("Friends"),
    SETTINGS("Settings")
}

@Composable
fun MainScreen(
    session: SessionState,
    users: List<User>,
    onRespondToInvite: (String, InviteAction) -> Unit,
    onSaveEvent: (Event) -> Unit,
    onSendFriendRequest: (String) -> Unit,
    onRemoveRequest: (String) -> Unit,
    onFriendshipUpdate: (String, FriendshipAction) -> Unit,
    onUpdateFullName: (String) -> Unit,
    onUpdateUsername: (String) -> Unit,
    onSignOut: () -> Unit
) {
    var selectedTab by remember { mutableStateOf(MainTab.EVENTS) }
    Scaffold(
        bottomBar = {
            NavigationBar {
                MainTab.values().forEach { tab ->
                    val icon = when (tab) {
                        MainTab.EVENTS -> Icons.Default.Event
                        MainTab.INVITES -> Icons.Default.Mail
                        MainTab.CREATE -> Icons.Default.AddCircle
                        MainTab.FRIENDS -> Icons.Default.Group
                        MainTab.SETTINGS -> Icons.Default.Settings
                    }
                    NavigationBarItem(
                        selected = tab == selectedTab,
                        onClick = { selectedTab = tab },
                        icon = { Icon(icon, contentDescription = tab.label) },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                MainTab.EVENTS -> EventsScreen(
                    user = session.user,
                    events = session.events,
                    users = users,
                    isInviteScreen = false,
                    onRespond = { event, action -> onRespondToInvite(event.id, action) },
                    onEventClick = { event ->
                        // TODO: Navigate to event detail screen
                        // For now, this is a placeholder
                    }
                )
                MainTab.INVITES -> EventsScreen(
                    user = session.user,
                    events = session.events,
                    users = users,
                    isInviteScreen = true,
                    onRespond = { event, action -> onRespondToInvite(event.id, action) },
                    onEventClick = { event ->
                        // TODO: Navigate to event detail screen
                        // For now, this is a placeholder
                    }
                )
                MainTab.CREATE -> CreateEventScreen(user = session.user, onSave = onSaveEvent)
                MainTab.FRIENDS -> FriendsScreen(
                    currentUserId = session.user?.uid,
                    users = users,
                    friendships = session.friendships,
                    friendRequests = session.friendRequests,
                    friendRequestsSent = session.friendRequestsSent,
                    onSendRequest = onSendFriendRequest,
                    onRemoveRequest = onRemoveRequest,
                    onUpdateFriendship = onFriendshipUpdate
                )
                MainTab.SETTINGS -> SettingsScreen(
                    user = session.user,
                    onUpdateFullName = onUpdateFullName,
                    onUpdateUsername = onUpdateUsername,
                    onSignOut = onSignOut
                )
            }
        }
    }
}
