package com.yallaconnect.app.ui.screens.events

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
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.yallaconnect.app.core.util.PhoneNumberFormatter
import com.yallaconnect.app.data.model.Event
import com.yallaconnect.app.data.model.User
import com.yallaconnect.app.data.repository.model.InviteAction
import com.yallaconnect.app.ui.theme.CliqueCardStroke
import com.yallaconnect.app.ui.theme.CliqueMutedText
import com.yallaconnect.app.ui.theme.CliqueOnPrimary
import com.yallaconnect.app.ui.theme.CliquePrimary
import com.yallaconnect.app.ui.theme.CliqueSecondary
import com.yallaconnect.app.ui.theme.CliqueSurface
import com.yallaconnect.app.ui.theme.CliqueSurfaceHighlight
import com.yallaconnect.app.ui.theme.TealAccent
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, h:mm a")
private val monthFormatter = DateTimeFormatter.ofPattern("MMM")
private val dayFormatter = DateTimeFormatter.ofPattern("d")
private val timeFormatter = DateTimeFormatter.ofPattern("h:mm a")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventsScreen(
    user: User?,
    events: List<Event>,
    users: List<User>,
    isInviteScreen: Boolean,
    onRespond: (Event, InviteAction) -> Unit,
    onEventClick: ((Event) -> Unit)? = null,
    onChatClick: ((Event) -> Unit)? = null,
    onRefresh: () -> Unit = {},
    onProfileClick: (() -> Unit)? = null
) {
    var filter by remember { mutableStateOf(if (isInviteScreen) InviteFilter.Pending else InviteFilter.Upcoming) }
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
    
    val filteredEvents = remember(events, user, filter, isInviteScreen) {
        when {
            user == null -> emptyList()
            isInviteScreen -> events.filter { event ->
                val invitedById = event.attendeesInvited.contains(user.uid)
                val invitedByPhone = event.invitedPhoneNumbers.any { PhoneNumberFormatter.numbersMatch(it, user.phoneNumber) }
                val declined = event.attendeesDeclined.contains(user.uid)
                when (filter) {
                    InviteFilter.Pending -> (invitedById || invitedByPhone) && !declined
                    InviteFilter.Declined -> declined
                    else -> false
                }
            }
            else -> events.filter { event ->
                // First check if user is part of the event (accepted or host)
                val isUserPartOfEvent = event.attendeesAccepted.contains(user.uid) || event.host == user.uid
                if (!isUserPartOfEvent) return@filter false
                
                when (filter) {
                    InviteFilter.Upcoming -> event.startDateTime.isAfter(Instant.now())
                    InviteFilter.Declined -> event.attendeesDeclined.contains(user.uid)
                    InviteFilter.Past -> event.startDateTime.isBefore(Instant.now())
                    InviteFilter.Pending -> false
                }
            }
        }
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
            // Header Section
            HeaderSection(
                title = if (isInviteScreen) "My Invites" else "My Events",
                user = user,
                onProfileClick = onProfileClick
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Segmented Control
            val options = if (isInviteScreen) listOf(InviteFilter.Pending, InviteFilter.Declined) else listOf(InviteFilter.Upcoming, InviteFilter.Past)
            SegmentedControl(
                options = options,
                selected = filter,
                onSelect = { filter = it },
                modifier = Modifier.padding(horizontal = 20.dp)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Events List or Empty State
            if (filteredEvents.isEmpty()) {
                EmptyStateCard(
                    title = when {
                        isInviteScreen && filter == InviteFilter.Pending -> "No Pending Invites"
                        isInviteScreen && filter == InviteFilter.Declined -> "No Declined Invites"
                        !isInviteScreen && filter == InviteFilter.Upcoming -> "No Upcoming Events"
                        !isInviteScreen && filter == InviteFilter.Past -> "No Past Events"
                        else -> "No Events"
                    },
                    message = when {
                        isInviteScreen && filter == InviteFilter.Pending -> "Invites you receive will be shown here"
                        isInviteScreen && filter == InviteFilter.Declined -> "Events you've declined will be shown here"
                        !isInviteScreen && filter == InviteFilter.Upcoming -> "Events you're attending will be shown here"
                        !isInviteScreen && filter == InviteFilter.Past -> "Past events you attended will be shown here"
                        else -> ""
                    },
                    icon = if (isInviteScreen) Icons.Default.Mail else Icons.Default.Event
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 20.dp, vertical = 8.dp)
                ) {
                    items(filteredEvents) { event ->
                        ModernEventCard(
                            event = event,
                            user = user,
                            users = users,
                            isInviteScreen = isInviteScreen,
                            onRespond = onRespond,
                            onClick = { onEventClick?.invoke(event) },
                            onChatClick = { onChatClick?.invoke(event) }
                        )
                    }
                }
            }
        }
        
        PullToRefreshContainer(
            state = pullRefreshState,
            modifier = Modifier.align(Alignment.TopCenter)
        )
    }
}

@Composable
private fun HeaderSection(title: String, user: User?, onProfileClick: (() -> Unit)? = null) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            fontSize = 32.sp,
            color = CliqueSecondary
        )
        
        if (user != null) {
            ProfilePicture(
                user = user, 
                size = 50.dp,
                onClick = onProfileClick
            )
        }
    }
}

@Composable
private fun ProfilePicture(user: User, size: androidx.compose.ui.unit.Dp, onClick: (() -> Unit)? = null) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(CliqueSurfaceHighlight)
            .border(1.dp, CliqueCardStroke, CircleShape)
            .then(
                if (onClick != null) {
                    Modifier.clickable { onClick() }
                } else {
                    Modifier
                }
            )
    ) {
        if (user.profilePic.isNotEmpty() && user.profilePic != "userDefault") {
            AsyncImage(
                model = user.profilePic,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // Placeholder
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(CliquePrimary.copy(alpha = 0.18f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = user.fullName.take(1).uppercase(),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = CliqueSecondary
                )
            }
        }
    }
}

@Composable
private fun SegmentedControl(
    options: List<InviteFilter>,
    selected: InviteFilter,
    onSelect: (InviteFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp)
            .background(CliqueSurfaceHighlight, RoundedCornerShape(14.dp))
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(14.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        options.forEach { option ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxSize()
                    .clip(RoundedCornerShape(10.dp))
                    .background(
                        if (selected == option) CliquePrimary else Color.Transparent
                    )
                    .clickable { onSelect(option) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = option.label,
                    color = if (selected == option) CliqueOnPrimary else CliqueMutedText,
                    fontWeight = if (selected == option) FontWeight.SemiBold else FontWeight.Medium,
                    fontSize = 15.sp
                )
            }
        }
    }
}

@Composable
private fun ModernEventCard(
    event: Event,
    user: User?,
    users: List<User>,
    isInviteScreen: Boolean,
    onRespond: (Event, InviteAction) -> Unit,
    onClick: (() -> Unit)?,
    onChatClick: ((Event) -> Unit)? = null
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(20.dp))
            .clickable(enabled = onClick != null) { onClick?.invoke() },
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = androidx.compose.material3.CardDefaults.cardElevation(defaultElevation = 10.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Image Section
            EventImageSection(
                event = event,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp),
                onChatClick = onChatClick ?: {}
            )
            
            // Details Section
            EventDetailsSection(
                event = event,
                user = user,
                users = users,
                isInviteScreen = isInviteScreen,
                onRespond = onRespond
            )
        }
    }
}

@Composable
private fun EventImageSection(
    event: Event,
    modifier: Modifier = Modifier,
    onChatClick: (Event) -> Unit = {}
) {
    Box(modifier = modifier) {
        // Background Image or Gradient
        if (event.eventPic.isNotEmpty() && event.eventPic != "userDefault") {
            AsyncImage(
                model = event.eventPic,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // Gradient placeholder
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                CliquePrimary.copy(alpha = 0.85f),
                                TealAccent.copy(alpha = 0.7f)
                            )
                        )
                    )
            )
        }
        
        // Gradient Overlay for text readability
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.75f)
                        )
                    )
                )
        )
        
        // Date Badge (Top Left)
        DateBadge(
            dateTime = event.startDateTime,
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(12.dp)
        )
        
        // Chat Badge (Top Right)
        ChatBadge(
            unreadCount = 0, // TODO: Implement unread count tracking
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(12.dp),
            onClick = { onChatClick(event) }
        )
        
        // Title and Location Overlay (Bottom)
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = event.title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                fontSize = 22.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = Color.White.copy(alpha = 0.9f)
                )
                Text(
                    text = event.location.split("||").firstOrNull() ?: event.location,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.9f),
                    fontSize = 14.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun DateBadge(dateTime: Instant, modifier: Modifier = Modifier) {
    val month = monthFormatter.format(dateTime.atZone(ZoneId.systemDefault())).uppercase()
    val day = dayFormatter.format(dateTime.atZone(ZoneId.systemDefault()))
    
    Column(
        modifier = modifier
            .background(Color.White.copy(alpha = 0.95f), RoundedCornerShape(10.dp))
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(10.dp))
            .padding(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            text = month,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = CliquePrimary,
            fontSize = 12.sp
        )
        Text(
            text = day,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp,
            color = CliqueSecondary
        )
    }
}

@Composable
private fun ChatBadge(
    unreadCount: Int,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val opacity = if (unreadCount == 0) 0.65f else 1.0f
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(
                Brush.horizontalGradient(
                    colors = listOf(
                        CliquePrimary.copy(alpha = 0.9f * opacity),
                        TealAccent.copy(alpha = 0.85f * opacity)
                    )
                )
            )
            .clickable { onClick() }
            .padding(horizontal = 10.dp, vertical = 6.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ChatBubble,
                contentDescription = null,
                modifier = Modifier.size(11.dp),
                tint = Color.White
            )
            Text(
                text = if (unreadCount > 99) "99+" else if (unreadCount == 0) "Chat" else unreadCount.toString(),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun EventDetailsSection(
    event: Event,
    user: User?,
    users: List<User>,
    isInviteScreen: Boolean,
    onRespond: (Event, InviteAction) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(CliqueSurfaceHighlight)
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top
        ) {
            // Time Info
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = "TIME",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = CliqueMutedText,
                    fontSize = 10.sp
                )
                Text(
                    text = timeFormatter.format(event.startDateTime.atZone(ZoneId.systemDefault())),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    fontSize = 16.sp,
                    color = CliqueSecondary
                )
            }
            
            // Host Info
            val host = users.find { it.uid == event.host }
            if (host != null) {
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "HOST",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = CliqueMutedText,
                        fontSize = 10.sp
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ProfilePicture(user = host, size = 24.dp)
                        Text(
                            text = host.fullName.split(" ").firstOrNull() ?: host.fullName,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            fontSize = 14.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            color = CliqueSecondary
                        )
                    }
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

enum class InviteFilter(val label: String) {
    Upcoming("Upcoming"),
    Past("Past"),
    Pending("Pending"),
    Declined("Declined")
}
