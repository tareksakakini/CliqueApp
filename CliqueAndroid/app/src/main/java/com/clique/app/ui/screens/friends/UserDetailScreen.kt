package com.clique.app.ui.screens.friends

import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.activity.compose.BackHandler
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clique.app.data.model.User
import com.clique.app.data.repository.model.FriendshipAction

enum class RelationshipStatus {
    FRIEND,
    REQUEST_RECEIVED,
    REQUEST_SENT,
    NONE
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserDetailScreen(
    user: User,
    currentUserId: String?,
    friendships: List<String>,
    friendRequests: List<String>,
    friendRequestsSent: List<String>,
    onBack: () -> Unit,
    onSendRequest: (String) -> Unit,
    onRemoveRequest: (String) -> Unit,
    onUpdateFriendship: (String, FriendshipAction) -> Unit
) {
    var showActionSheet by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState()
    
    val relationshipStatus = remember(user.uid, friendships, friendRequests, friendRequestsSent) {
        when {
            friendships.contains(user.uid) -> RelationshipStatus.FRIEND
            friendRequests.contains(user.uid) -> RelationshipStatus.REQUEST_RECEIVED
            friendRequestsSent.contains(user.uid) -> RelationshipStatus.REQUEST_SENT
            else -> RelationshipStatus.NONE
        }
    }

    // Handle Android back button
    BackHandler(enabled = true) {
        if (showActionSheet) {
            showActionSheet = false
        } else {
            onBack()
        }
    }

    Scaffold(
        containerColor = Color(0xFFF5F5F5)
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            Spacer(modifier = Modifier.height(20.dp))
            
            // Profile Section
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                // Profile Picture
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFE0E0E0)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "Profile",
                        tint = Color.White,
                        modifier = Modifier.size(60.dp)
                    )
                }
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Name and Username
                Text(
                    user.fullName,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 28.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "@${user.username}",
                    style = MaterialTheme.typography.bodyLarge,
                    color = Color.Gray,
                    fontSize = 18.sp
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Relationship Status Button
            RelationshipStatusButton(
                status = relationshipStatus,
                onClick = { showActionSheet = true }
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Profile Details Card
            ProfileDetailsCard(user = user)
            
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
    
    // Action Sheet
    if (showActionSheet) {
        ModalBottomSheet(
            onDismissRequest = { showActionSheet = false },
            sheetState = sheetState,
            containerColor = Color.White,
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
        ) {
            ActionSheetContent(
                status = relationshipStatus,
                userName = user.fullName,
                onDismiss = { showActionSheet = false },
                onRemoveFriend = {
                    onUpdateFriendship(user.uid, FriendshipAction.REMOVE)
                    showActionSheet = false
                },
                onAcceptRequest = {
                    onUpdateFriendship(user.uid, FriendshipAction.ADD)
                    showActionSheet = false
                },
                onDeclineRequest = {
                    onRemoveRequest(user.uid)
                    showActionSheet = false
                },
                onUnsendRequest = {
                    onRemoveRequest(user.uid)
                    showActionSheet = false
                },
                onSendRequest = {
                    onSendRequest(user.uid)
                    showActionSheet = false
                }
            )
        }
    }
}

@Composable
private fun RelationshipStatusButton(
    status: RelationshipStatus,
    onClick: () -> Unit
) {
    val (backgroundColor, icon, text) = when (status) {
        RelationshipStatus.FRIEND -> Triple(
            Color(0xFF4CAF50),
            Icons.Default.Check,
            "Friends"
        )
        RelationshipStatus.REQUEST_RECEIVED -> Triple(
            Color(0xFF6BBFA8),
            Icons.Default.Person,
            "Friendship Requested"
        )
        RelationshipStatus.REQUEST_SENT -> Triple(
            Color(0xFFFF9800),
            Icons.Default.Person,
            "Pending"
        )
        RelationshipStatus.NONE -> Triple(
            Color(0xFF6BBFA8),
            Icons.Default.PersonAdd,
            "Add Friend"
        )
    }
    
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        Button(
            onClick = onClick,
            colors = ButtonDefaults.buttonColors(
                containerColor = backgroundColor
            ),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.height(48.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun ProfileDetailsCard(user: User) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(28.dp)) {
            Text(
                "Profile Details",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Full Name
            ProfileDetailRow(
                icon = Icons.Default.Person,
                title = "FULL NAME",
                value = user.fullName,
                showChevron = false
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color(0xFFE0E0E0))
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            // Username
            ProfileDetailRow(
                icon = Icons.Default.Person,
                title = "USERNAME",
                value = "@${user.username}",
                showChevron = false
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color(0xFFE0E0E0))
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            // Friends Count (placeholder - you can add actual count if available)
            ProfileDetailRow(
                icon = Icons.Default.Person,
                title = "FRIENDS",
                value = "5 friends", // Placeholder
                showChevron = true
            )
        }
    }
}

@Composable
private fun ProfileDetailRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    value: String,
    showChevron: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Color(0xFFF5F5F5)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Color(0xFF757575),
                modifier = Modifier.size(20.dp)
            )
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.labelSmall,
                color = Color.Gray,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                value,
                style = MaterialTheme.typography.bodyLarge,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium
            )
        }
        
        if (showChevron) {
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color(0xFFBDBDBD),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun ActionSheetContent(
    status: RelationshipStatus,
    userName: String,
    onDismiss: () -> Unit,
    onRemoveFriend: () -> Unit,
    onAcceptRequest: () -> Unit,
    onDeclineRequest: () -> Unit,
    onUnsendRequest: () -> Unit,
    onSendRequest: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
    ) {
        when (status) {
            RelationshipStatus.FRIEND -> {
                ActionSheetButton(
                    text = "Remove Friend",
                    isDestructive = true,
                    onClick = onRemoveFriend
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
            RelationshipStatus.REQUEST_RECEIVED -> {
                ActionSheetButton(
                    text = "Accept Friend Request",
                    isDestructive = false,
                    onClick = onAcceptRequest
                )
                Spacer(modifier = Modifier.height(12.dp))
                ActionSheetButton(
                    text = "Decline Request",
                    isDestructive = true,
                    onClick = onDeclineRequest
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
            RelationshipStatus.REQUEST_SENT -> {
                ActionSheetButton(
                    text = "Unsend Request",
                    isDestructive = true,
                    onClick = onUnsendRequest
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
            RelationshipStatus.NONE -> {
                ActionSheetButton(
                    text = "Send Friend Request",
                    isDestructive = false,
                    onClick = onSendRequest
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
        }
        
        ActionSheetButton(
            text = "Cancel",
            isDestructive = false,
            onClick = onDismiss
        )
        
        Spacer(modifier = Modifier.height(20.dp))
    }
}

@Composable
private fun ActionSheetButton(
    text: String,
    isDestructive: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isDestructive) Color(0xFFFF5252) else Color(0xFF6BBFA8)
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Text(
            text,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White
        )
    }
}

