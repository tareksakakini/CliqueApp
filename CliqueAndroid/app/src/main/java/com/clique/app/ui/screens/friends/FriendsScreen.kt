package com.clique.app.ui.screens.friends

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.clique.app.data.model.User
import com.clique.app.data.repository.model.FriendshipAction

@Composable
fun FriendsScreen(
    currentUserId: String?,
    users: List<User>,
    friendships: List<String>,
    friendRequests: List<String>,
    friendRequestsSent: List<String>,
    onSendRequest: (String) -> Unit,
    onRemoveRequest: (String) -> Unit,
    onUpdateFriendship: (String, FriendshipAction) -> Unit
) {
    var selectedTab by remember { mutableStateOf(0) }
    var query by remember { mutableStateOf("") }
    val sections = listOf("Friends", "Requests", "Sent")
    var inviteHandle by remember { mutableStateOf("") }
    val inviteCandidate = remember(inviteHandle, users) {
        users.firstOrNull { it.username.equals(inviteHandle.trim(), ignoreCase = true) }
    }
    val map = users.associateBy { it.uid }
    val results = remember(selectedTab, friendships, friendRequests, friendRequestsSent, query) {
        val source = when (selectedTab) {
            0 -> friendships.mapNotNull { map[it] }
            1 -> friendRequests.mapNotNull { map[it] }
            else -> friendRequestsSent.mapNotNull { map[it] }
        }
        if (query.isBlank()) source else source.filter {
            it.fullName.contains(query, ignoreCase = true) || it.username.contains(query, ignoreCase = true)
        }
    }

    Column(modifier = Modifier.padding(16.dp)) {
        Text("My Friends", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Search") }
        )
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedTextField(
            value = inviteHandle,
            onValueChange = { inviteHandle = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Add friend by username") }
        )
        val canInvite = inviteCandidate != null &&
            inviteCandidate.uid != currentUserId &&
            !friendships.contains(inviteCandidate.uid) &&
            !friendRequestsSent.contains(inviteCandidate.uid)
        if (canInvite && inviteCandidate != null) {
            TextButton(onClick = { onSendRequest(inviteCandidate.uid) }) {
                Text("Send invite to @${inviteCandidate.username}")
            }
        }
        Spacer(modifier = Modifier.height(12.dp))
        TabRow(selectedTabIndex = selectedTab) {
            sections.forEachIndexed { index, title ->
                Tab(selected = selectedTab == index, onClick = { selectedTab = index }, text = { Text(title) })
            }
        }
        Spacer(modifier = Modifier.height(12.dp))
        LazyColumn {
            items(results) { user ->
                FriendCard(
                    user = user,
                    section = selectedTab,
                    onAcceptRequest = {
                        onUpdateFriendship(user.uid, FriendshipAction.ADD)
                        onRemoveRequest(user.uid)
                    },
                    onRemoveRequest = { onRemoveRequest(user.uid) },
                    onRemoveFriend = { onUpdateFriendship(user.uid, FriendshipAction.REMOVE) }
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
        }
    }
}

@Composable
private fun FriendCard(
    user: User,
    section: Int,
    onAcceptRequest: () -> Unit,
    onRemoveRequest: () -> Unit,
    onRemoveFriend: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(12.dp)
    ) {
        Text(user.fullName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text("@${user.username}", style = MaterialTheme.typography.bodySmall)
        Spacer(modifier = Modifier.height(8.dp))
        Row {
            when (section) {
                0 -> OutlinedButton(onClick = onRemoveFriend) { Text("Remove") }
                1 -> {
                    Button(onClick = onAcceptRequest) { Text("Accept") }
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedButton(onClick = onRemoveRequest) { Text("Dismiss") }
                }
                2 -> OutlinedButton(onClick = onRemoveRequest) { Text("Cancel") }
            }
        }
    }
}
