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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
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
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")
private val timeFormatter = DateTimeFormatter.ofPattern("h:mm a")

@Composable
fun EventDetailScreen(
    eventId: String,
    inviteView: Boolean,
    user: User?,
    users: List<User>,
    events: List<Event>,
    onBack: () -> Unit,
    onEdit: ((Event) -> Unit)? = null,
    onDelete: ((Event) -> Unit)? = null,
    onRespond: ((Event, InviteAction) -> Unit)? = null,
    onChatClick: ((Event) -> Unit)? = null,
    onRefreshEvent: suspend (String) -> Event? = { null }
) {
    val event = remember(eventId, events) { events.find { it.id == eventId } }
    var currentEvent by remember { mutableStateOf(event) }
    
    LaunchedEffect(eventId) {
        val refreshed = onRefreshEvent(eventId)
        if (refreshed != null) {
            currentEvent = refreshed
        } else if (event != null) {
            currentEvent = event
        }
    }
    
    if (currentEvent == null || user == null) {
        onBack()
        return
    }
    
    val isHost = currentEvent!!.host == user.uid
    val isEventPast = currentEvent!!.startDateTime.isBefore(Instant.now())
    
    Box(
        modifier = Modifier
            .fillMaxSize()
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(top = 24.dp)
        ) {
            // Hero Image Section
            HeroImageSection(
                event = currentEvent!!,
                showEditButton = isHost && !isEventPast && onEdit != null,
                onEdit = { onEdit?.invoke(currentEvent!!) }
            )
            
            // Location Card
            LocationCard(event = currentEvent!!)
            
            // Description Card (if description exists)
            if (currentEvent!!.description.isNotEmpty()) {
                DescriptionCard(event = currentEvent!!)
            }
            
            // Invitees Card
            InviteesCard(
                event = currentEvent!!,
                user = user,
                users = users
            )
            
            // Host Card
            HostCard(
                event = currentEvent!!,
                user = user,
                users = users
            )
            
            // Chat Entry Point
            ChatEntryPoint(
                event = currentEvent!!,
                onClick = { onChatClick?.invoke(currentEvent!!) }
            )
            
            // Action Buttons (for non-host, non-past events)
            if (!isEventPast && !isHost && onRespond != null) {
                ActionButtonsSection(
                    event = currentEvent!!,
                    user = user,
                    onRespond = onRespond
                )
            }
            
            // Delete Button (for host)
            if (isHost && onDelete != null) {
                DeleteButtonSection(
                    event = currentEvent!!,
                    onDelete = { onDelete(currentEvent!!) }
                )
            }
            
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}


@Composable
private fun HeroImageSection(
    event: Event,
    showEditButton: Boolean = false,
    onEdit: (() -> Unit)? = null
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 20.dp)
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(20.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(250.dp)
        ) {
            // Background Image or Gradient
            if (event.eventPic.isNotEmpty() && event.eventPic != "userDefault") {
                AsyncImage(
                    model = event.eventPic,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(
                                    CliquePrimary.copy(alpha = 0.9f),
                                    TealAccent.copy(alpha = 0.75f)
                                )
                            )
                        )
                )
            }
            
            // Gradient Overlay
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.1f),
                                Color.Black.copy(alpha = 0.35f),
                                Color.Black.copy(alpha = 0.6f),
                                Color.Black.copy(alpha = 0.75f)
                            )
                        )
                    )
            )
            
            // Edit Button (top right overlay)
            if (showEditButton && onEdit != null) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.95f))
                            .border(1.dp, CliqueCardStroke, CircleShape)
                            .clickable { onEdit() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "Edit",
                            modifier = Modifier.size(18.dp),
                            tint = CliquePrimary
                        )
                    }
                }
            }
            
            // Title and Date/Time
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = event.title,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    fontSize = 28.sp
                )
                
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Date
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.CalendarToday,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = Color.White.copy(alpha = 0.9f)
                        )
                        Text(
                            text = dateFormatter.format(event.startDateTime.atZone(ZoneId.systemDefault())),
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.9f),
                            fontSize = 16.sp
                        )
                    }
                    
                    // Time
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = Color.White.copy(alpha = 0.9f)
                        )
                        Text(
                            text = timeFormatter.format(event.startDateTime.atZone(ZoneId.systemDefault())),
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.9f),
                            fontSize = 16.sp
                        )
                    }
                    
                    // Duration (if not noEndTime)
                    if (!event.noEndTime) {
                        val duration = Duration.between(event.startDateTime, event.endDateTime)
                        val hours = duration.toHours()
                        val minutes = duration.toMinutes() % 60
                        val durationText = when {
                            hours > 0 && minutes > 0 -> "${hours}h ${minutes}m"
                            hours > 0 -> "${hours}h"
                            else -> "${minutes}m"
                        }
                        
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Timer,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = Color.White.copy(alpha = 0.9f)
                            )
                            Text(
                                text = durationText,
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.9f),
                                fontSize = 16.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun LocationCard(event: Event) {
    val locationParts = event.location.split("||")
    val locationTitle = locationParts.firstOrNull() ?: event.location
    val locationAddress = if (locationParts.size > 1) locationParts[1] else ""
    
    InfoCard(
        icon = Icons.Default.LocationOn,
        title = "LOCATION",
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = locationTitle,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                color = CliqueSecondary
            )
            
            if (locationAddress.isNotEmpty()) {
                Text(
                    text = locationAddress,
                    style = MaterialTheme.typography.bodyMedium,
                    color = CliqueMutedText,
                    fontSize = 16.sp
                )
            }
        }
    }
}

@Composable
private fun DescriptionCard(event: Event) {
    InfoCard(
        icon = Icons.Default.ChatBubble,
        title = "DESCRIPTION",
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        Text(
            text = event.description,
            style = MaterialTheme.typography.bodyMedium,
            fontSize = 16.sp,
            lineHeight = 24.sp,
            color = CliqueSecondary
        )
    }
}

@Composable
private fun InviteesCard(
    event: Event,
    user: User,
    users: List<User>
) {
    val acceptedIds = event.attendeesAccepted
    val invitedIds = event.attendeesInvited
    val declinedIds = event.attendeesDeclined
    
    val totalInvitees = acceptedIds.size + invitedIds.size + declinedIds.size +
            event.acceptedPhoneNumbers.size + event.invitedPhoneNumbers.size + event.declinedPhoneNumbers.size
    
    val pendingCount = invitedIds.size + event.invitedPhoneNumbers.size
    
    InfoCard(
        icon = Icons.Default.People,
        title = "INVITEES",
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        badge = totalInvitees.toString()
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Pending Section
            if (pendingCount > 0) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "PENDING",
                        style = MaterialTheme.typography.labelMedium,
                        color = CliqueMutedText,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Badge(
                        text = pendingCount.toString(),
                        color = Color(0xFFFF9500) // Orange
                    )
                }
                
                // Pending Invitees
                invitedIds.forEach { inviteeId ->
                    val invitee = users.find { it.uid == inviteeId }
                    if (invitee != null) {
                        InviteeRow(
                            user = invitee,
                            status = "pending"
                        )
                    }
                }
            }
            
            // Accepted Section
            if (acceptedIds.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "ACCEPTED",
                        style = MaterialTheme.typography.labelMedium,
                        color = CliqueMutedText,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Badge(
                        text = acceptedIds.size.toString(),
                        color = Color(0xFF34C759) // Green
                    )
                }
                
                acceptedIds.forEach { acceptedId ->
                    val accepted = users.find { it.uid == acceptedId }
                    if (accepted != null) {
                        InviteeRow(
                            user = accepted,
                            status = "accepted"
                        )
                    }
                }
            }
            
            // Declined Section
            if (declinedIds.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "DECLINED",
                        style = MaterialTheme.typography.labelMedium,
                        color = CliqueMutedText,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Badge(
                        text = declinedIds.size.toString(),
                        color = Color(0xFFFF3B30) // Red
                    )
                }
                
                declinedIds.forEach { declinedId ->
                    val declined = users.find { it.uid == declinedId }
                    if (declined != null) {
                        InviteeRow(
                            user = declined,
                            status = "declined"
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun InviteeRow(user: User, status: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        ProfilePicture(user = user, size = 50.dp)
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = user.fullName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                color = CliqueSecondary
            )
            Text(
                text = "@${user.username.ifEmpty { "username" }}",
                style = MaterialTheme.typography.bodyMedium,
                color = CliqueMutedText,
                fontSize = 14.sp
            )
        }
        
        // Status Icon
        when (status) {
            "pending" -> Icon(
                imageVector = Icons.Default.Schedule,
                contentDescription = "Pending",
                modifier = Modifier.size(24.dp),
                tint = Color(0xFFFF9500)
            )
            "accepted" -> Icon(
                imageVector = Icons.Default.Person,
                contentDescription = "Accepted",
                modifier = Modifier.size(24.dp),
                tint = Color(0xFF34C759)
            )
            "declined" -> Icon(
                imageVector = Icons.Default.Person,
                contentDescription = "Declined",
                modifier = Modifier.size(24.dp),
                tint = Color(0xFFFF3B30)
            )
        }
    }
}

@Composable
private fun HostCard(
    event: Event,
    user: User,
    users: List<User>
) {
    val host = users.find { it.uid == event.host }
    if (host == null) return
    
    val isViewingUser = host.uid == user.uid
    
    InfoCard(
        icon = Icons.Default.Person, // Using Person as crown icon might not be available
        title = "HOST",
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ProfilePicture(user = host, size = 50.dp)
            
            Column {
                Text(
                    text = if (isViewingUser) "You" else host.fullName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 18.sp,
                    color = CliqueSecondary
                )
                Text(
                    text = "@${host.username.ifEmpty { "username" }}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = CliqueMutedText,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun ChatEntryPoint(
    event: Event,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, CliqueCardStroke)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.ChatBubble,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = CliquePrimary
                )
                Column {
                    Text(
                        text = "Event Chat",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 18.sp,
                        color = CliqueSecondary
                    )
                    Text(
                        text = "Last message preview...", // TODO: Get actual last message
                        style = MaterialTheme.typography.bodyMedium,
                        color = CliqueMutedText,
                        fontSize = 14.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            
            // Unread badge
            Badge(
                text = "1", // TODO: Get actual unread count
                color = CliquePrimary
            )
        }
    }
}

@Composable
private fun ActionButtonsSection(
    event: Event,
    user: User,
    onRespond: (Event, InviteAction) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Accept Button
        Button(
            onClick = { onRespond(event, InviteAction.ACCEPT) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = CliquePrimary,
                contentColor = CliqueOnPrimary
            )
        ) {
            Text("Accept Invite", modifier = Modifier.padding(vertical = 8.dp))
        }
        
        // Decline Button
        OutlinedButton(
            onClick = { onRespond(event, InviteAction.DECLINE) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = CliqueSecondary
            ),
            border = androidx.compose.foundation.BorderStroke(1.dp, CliqueCardStroke)
        ) {
            Text("Decline Invite", modifier = Modifier.padding(vertical = 8.dp))
        }
    }
}

@Composable
private fun DeleteButtonSection(
    event: Event,
    onDelete: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        OutlinedButton(
            onClick = onDelete,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            border = androidx.compose.foundation.BorderStroke(2.dp, Color.Red),
            colors = androidx.compose.material3.ButtonDefaults.outlinedButtonColors(
                contentColor = Color.Red
            )
        ) {
            Icon(
                imageVector = Icons.Default.Delete,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("Delete Event", modifier = Modifier.padding(vertical = 8.dp))
        }
    }
}

@Composable
private fun InfoCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    modifier: Modifier = Modifier,
    badge: String? = null,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier
            .border(1.dp, CliqueCardStroke, RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = CliquePrimary
                    )
                    Text(
                        text = title,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = CliqueMutedText,
                        fontSize = 12.sp
                    )
                }
                
                if (badge != null) {
                    Badge(text = badge, color = CliquePrimary)
                }
            }
            
            content()
        }
    }
}

@Composable
private fun Badge(text: String, color: Color) {
    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.12f), RoundedCornerShape(8.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = color,
            fontSize = 16.sp
        )
    }
}

@Composable
private fun ProfilePicture(user: User, size: androidx.compose.ui.unit.Dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(CliqueSurfaceHighlight)
            .border(1.dp, CliqueCardStroke, CircleShape)
    ) {
        if (user.profilePic.isNotEmpty() && user.profilePic != "userDefault") {
            AsyncImage(
                model = user.profilePic,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
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
