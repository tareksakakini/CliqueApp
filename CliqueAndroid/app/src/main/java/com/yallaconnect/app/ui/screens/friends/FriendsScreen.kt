package com.yallaconnect.app.ui.screens.friends

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import com.yallaconnect.app.data.repository.CliqueRepository
import com.google.firebase.firestore.ListenerRegistration
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.yallaconnect.app.data.model.User
import com.yallaconnect.app.data.repository.model.FriendshipAction
import com.yallaconnect.app.ui.theme.CliqueCardStroke
import com.yallaconnect.app.ui.theme.CliqueMutedText
import com.yallaconnect.app.ui.theme.CliquePrimary
import com.yallaconnect.app.ui.theme.CliqueSecondary
import com.yallaconnect.app.ui.theme.CliqueSurface
import com.yallaconnect.app.ui.theme.CliqueSurfaceHighlight
import com.yallaconnect.app.ui.theme.TealAccent
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendsScreen(
    currentUserId: String?,
    users: List<User>,
    friendships: List<String>,
    friendRequests: List<String>,
    friendRequestsSent: List<String>,
    repository: CliqueRepository,
    onSendRequest: (String) -> Unit,
    onRemoveRequest: (String) -> Unit,
    onUpdateFriendship: (String, FriendshipAction) -> Unit,
    onRefresh: () -> Unit = {}
) {
    var selectedFilter by remember { mutableStateOf(0) } // 0=Friends, 1=Requests, 2=Sent
    var showAddFriendDialog by remember { mutableStateOf(false) }
    var selectedUser by remember { mutableStateOf<User?>(null) }
    var viewingUserFriends by remember { mutableStateOf<Pair<String, List<User>>?>(null) }
    val pullRefreshState = rememberPullToRefreshState()
    val coroutineScope = rememberCoroutineScope()
    
    if (pullRefreshState.isRefreshing) {
        LaunchedEffect(true) {
            coroutineScope.launch {
                onRefresh()
                delay(500) // Small delay for better UX
                pullRefreshState.endRefresh()
            }
        }
    }
    
    val map = users.associateBy { it.uid }
    val friendsList = remember(friendships) { friendships.mapNotNull { map[it] } }
    val requestsList = remember(friendRequests) { friendRequests.mapNotNull { map[it] } }
    val sentList = remember(friendRequestsSent) { friendRequestsSent.mapNotNull { map[it] } }
    
    val displayedUsers = remember(selectedFilter, friendsList, requestsList, sentList) {
        when (selectedFilter) {
            0 -> friendsList
            1 -> requestsList
            else -> sentList
        }
    }

    // Show user's friends list if viewing
    if (viewingUserFriends != null) {
        UserFriendsListScreen(
            userName = users.find { it.uid == viewingUserFriends!!.first }?.fullName ?: "User",
            friends = viewingUserFriends!!.second,
            users = users,
            onBack = { viewingUserFriends = null },
            onUserClick = { user ->
                viewingUserFriends = null
                selectedUser = user
            }
        )
        return
    }
    
    // Show detail screen if user is selected
    if (selectedUser != null) {
        UserDetailScreen(
            user = selectedUser!!,
            currentUserId = currentUserId,
            friendships = friendships,
            friendRequests = friendRequests,
            friendRequestsSent = friendRequestsSent,
            users = users,
            repository = repository,
            onBack = { selectedUser = null },
            onSendRequest = onSendRequest,
            onRemoveRequest = onRemoveRequest,
            onUpdateFriendship = onUpdateFriendship,
            onShowFriends = { userId, friendsUsers ->
                viewingUserFriends = Pair(userId, friendsUsers)
            }
        )
        return
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .nestedScroll(pullRefreshState.nestedScrollConnection)
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        CliqueSurface,
                        CliqueSurfaceHighlight,
                        CliqueSurface
                    )
                )
            )
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "My Friends",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 32.sp,
                    color = CliqueSecondary
                )
                Button(
                    onClick = { showAddFriendDialog = true },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = CliquePrimary,
                        contentColor = Color.White
                    ),
                    modifier = Modifier.height(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Add",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Add Friend", fontWeight = FontWeight.SemiBold)
                }
            }

            // Your Network Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .border(1.dp, CliqueCardStroke, RoundedCornerShape(20.dp)),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        "Your Network",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        fontSize = 24.sp,
                        color = CliqueSecondary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "Tap to filter your connections",
                        style = MaterialTheme.typography.bodyMedium,
                        color = CliqueMutedText
                    )
                    Spacer(modifier = Modifier.height(20.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        NetworkFilterItem(
                            icon = Icons.Default.Person,
                            count = friendships.size,
                            label = "FRIENDS",
                            isSelected = selectedFilter == 0,
                            onClick = { selectedFilter = 0 }
                        )
                        NetworkFilterItem(
                            icon = Icons.Default.Email,
                            count = friendRequests.size,
                            label = "REQUESTS",
                            isSelected = selectedFilter == 1,
                            onClick = { selectedFilter = 1 }
                        )
                        NetworkFilterItem(
                            icon = Icons.AutoMirrored.Filled.Send,
                            count = friendRequestsSent.size,
                            label = "SENT",
                            isSelected = selectedFilter == 2,
                            onClick = { selectedFilter = 2 }
                        )
                    }
                }
            }

            // Friends Section
            Spacer(modifier = Modifier.height(24.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Friends",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp,
                    color = CliqueSecondary
                )
            }
            Spacer(modifier = Modifier.height(16.dp))

            // Friends List or Empty State
            if (displayedUsers.isEmpty()) {
                EmptyStateCard(
                    title = when (selectedFilter) {
                        0 -> "No Friends"
                        1 -> "No Friend Requests"
                        else -> "No Sent Requests"
                    },
                    message = when (selectedFilter) {
                        0 -> "Your friends will be shown here"
                        1 -> "Friend requests you receive will be shown here"
                        else -> "Friend requests you've sent will be shown here"
                    },
                    icon = when (selectedFilter) {
                        0 -> Icons.Default.Person
                        1 -> Icons.Default.Email
                        else -> Icons.AutoMirrored.Filled.Send
                    }
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth(),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 20.dp, vertical = 8.dp)
                ) {
                    items(displayedUsers) { user ->
                        FriendCard(
                            user = user,
                            section = selectedFilter,
                            onClick = { selectedUser = user },
                            onAcceptRequest = {
                                onUpdateFriendship(user.uid, FriendshipAction.ADD)
                            },
                            onRemoveRequest = { onRemoveRequest(user.uid) },
                            onRemoveFriend = { onUpdateFriendship(user.uid, FriendshipAction.REMOVE) }
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }
            }
        }

        // Add Friend Dialog
        if (showAddFriendDialog) {
            AddFriendDialog(
                users = users,
                currentUserId = currentUserId,
                friendships = friendships,
                friendRequestsSent = friendRequestsSent,
                onDismiss = { showAddFriendDialog = false },
                onUserSelected = { user ->
                    selectedUser = user
                    showAddFriendDialog = false
                }
            )
        }
        
        PullToRefreshContainer(
            state = pullRefreshState,
            modifier = Modifier.align(Alignment.TopCenter)
        )
    }
}

@Composable
private fun NetworkFilterItem(
    icon: ImageVector,
    count: Int,
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(
                    if (isSelected) CliquePrimary else CliqueSurfaceHighlight
                )
                .border(1.dp, if (isSelected) CliquePrimary else CliqueCardStroke, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (isSelected) Color.White else CliquePrimary,
                modifier = Modifier.size(28.dp)
            )
        }
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            count.toString(),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp,
            color = CliqueSecondary
        )
        Text(
            label,
            style = MaterialTheme.typography.labelMedium,
            color = if (isSelected) CliquePrimary else CliqueMutedText,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun FriendCard(
    user: User,
    section: Int,
    onClick: () -> Unit,
    onAcceptRequest: () -> Unit = {},
    onRemoveRequest: () -> Unit = {},
    onRemoveFriend: () -> Unit = {}
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        border = BorderStroke(1.dp, CliqueCardStroke)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Profile Image Placeholder
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(CliquePrimary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = "Profile",
                    tint = CliquePrimary,
                    modifier = Modifier.size(32.dp)
                )
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    user.fullName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = CliqueSecondary
                )
                Text(
                    "@${user.username}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = CliqueMutedText,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddFriendDialog(
    users: List<User>,
    currentUserId: String?,
    friendships: List<String>,
    friendRequestsSent: List<String>,
    onDismiss: () -> Unit,
    onUserSelected: (User) -> Unit
) {
    var inviteHandle by remember { mutableStateOf("") }
    val searchQuery = inviteHandle.trim()
    val inviteCandidates = remember(searchQuery, users, currentUserId, friendships, friendRequestsSent) {
        if (searchQuery.isBlank()) {
            emptyList()
        } else {
            users.filter { user ->
                user.fullName.contains(searchQuery, ignoreCase = true) &&
                user.uid != currentUserId &&
                !friendships.contains(user.uid) &&
                !friendRequestsSent.contains(user.uid)
            }.take(3)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .clickable(enabled = false) { }, // Prevent dismiss when clicking card
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
            ) {
                Text(
                    "Add Friend",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = inviteHandle,
                    onValueChange = { inviteHandle = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Name") },
                    placeholder = { Text("Search by name...") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = "Search",
                            tint = CliqueMutedText
                        )
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = CliquePrimary,
                        unfocusedBorderColor = CliqueCardStroke
                    )
                )
                
                if (inviteCandidates.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        inviteCandidates.forEach { candidate ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        onUserSelected(candidate)
                                    },
                                colors = CardDefaults.cardColors(
                                    containerColor = CliqueSurfaceHighlight
                                ),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(CliquePrimary.copy(alpha = 0.12f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Person,
                                        contentDescription = "Profile",
                                        tint = CliquePrimary
                                    )
                                }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            candidate.fullName,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                        Text(
                                            "@${candidate.username}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = CliqueMutedText
                                        )
                                    }
                                }
                            }
                        }
                    }
                } else if (searchQuery.isNotBlank()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        "No users found",
                        style = MaterialTheme.typography.bodyMedium,
                        color = CliqueMutedText,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

@Composable
private fun UserFriendsListScreen(
    userName: String,
    friends: List<User>,
    users: List<User>,
    onBack: () -> Unit,
    onUserClick: (User) -> Unit
) {
    Scaffold(
        topBar = {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = Color.White,
                tonalElevation = 2.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onBack) {
                        Text("Back", color = CliquePrimary)
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "$userName's Friends",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        fontSize = 24.sp,
                        color = CliqueSecondary
                    )
                }
            }
        },
        containerColor = CliqueSurface
    ) { paddingValues ->
        if (friends.isEmpty()) {
            EmptyStateCard(
                title = "No Friends",
                message = "$userName hasn't added any friends yet",
                icon = Icons.Default.Person
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 20.dp, vertical = 8.dp)
            ) {
                items(friends) { friend ->
                    FriendCard(
                        user = friend,
                        section = 0,
                        onClick = { onUserClick(friend) }
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                }
            }
        }
    }
}

@Composable
private fun EmptyStateCard(
    title: String,
    message: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp)
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(20.dp)),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(Color.White),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = CliqueMutedText.copy(alpha = 0.6f)
                )
            }
            
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp,
                color = CliqueSecondary
            )
            
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = CliqueMutedText,
                fontSize = 14.sp,
                textAlign = TextAlign.Center
            )
        }
    }
}
