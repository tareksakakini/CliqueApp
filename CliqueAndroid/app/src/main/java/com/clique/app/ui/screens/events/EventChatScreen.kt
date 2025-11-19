package com.clique.app.ui.screens.events

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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.clique.app.data.model.Event
import com.clique.app.data.model.EventChatMessage
import com.clique.app.data.model.User
import com.clique.app.ui.theme.TealAccent
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import kotlinx.coroutines.delay

private val timeFormatter = DateTimeFormatter.ofPattern("h:mm a")
private val dayFormatter = DateTimeFormatter.ofPattern("EEEE, MMM d")

@Composable
fun EventChatScreen(
    event: Event,
    user: User,
    users: List<User>,
    messages: List<EventChatMessage>,
    composerText: String,
    onComposerTextChange: (String) -> Unit,
    onSendMessage: () -> Unit,
    onBack: () -> Unit
) {
    val listState = rememberLazyListState()
    
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            delay(100)
            listState.animateScrollToItem(messages.size - 1)
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5))
    ) {
        ChatHeader(
            eventTitle = event.title,
            onBack = onBack
        )
        
        Divider()
        
        if (messages.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                EmptyChatView(eventTitle = event.title)
            }
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 20.dp, vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(0.dp)
            ) {
                itemsIndexed(messages) { index, message ->
                    val shouldGroup = shouldGroupWithPrevious(index, messages)
                    val shouldShowDayDivider = shouldShowDayDivider(index, messages)
                    
                    if (shouldShowDayDivider) {
                        DayDivider(
                            date = message.createdAt,
                            modifier = Modifier.padding(
                                top = if (index == 0) 12.dp else 20.dp,
                                bottom = 8.dp
                            )
                        )
                    }
                    
                    ChatBubble(
                        message = message,
                        isCurrentUser = message.senderId == user.uid || message.senderHandle == user.uid,
                        showsSenderName = !shouldGroup || message.senderId == user.uid || message.senderHandle == user.uid,
                        users = users,
                        hostId = event.host,
                        modifier = Modifier.padding(top = if (shouldGroup) 4.dp else 12.dp)
                    )
                }
                
                item {
                    Spacer(modifier = Modifier.height(18.dp))
                }
            }
        }
        
        ChatComposer(
            text = composerText,
            onTextChange = onComposerTextChange,
            onSend = onSendMessage,
            enabled = composerText.trim().isNotEmpty()
        )
    }
}

@Composable
private fun ChatHeader(eventTitle: String, onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.ArrowBack,
            contentDescription = "Back",
            modifier = Modifier
                .size(44.dp)
                .clickable { onBack() },
            tint = Color.Black
        )
        
        Text(
            text = eventTitle,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp,
            modifier = Modifier.padding(start = 8.dp),
            maxLines = 1
        )
    }
}

@Composable
private fun EmptyChatView(eventTitle: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(top = 80.dp)
    ) {
            Icon(
                imageVector = Icons.Default.Send,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = TealAccent
            )
            Text(
                text = "No messages yet",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp
            )
            Text(
                text = "Start the conversation for $eventTitle",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray,
                fontSize = 14.sp
            )
    }
}

@Composable
private fun DayDivider(date: Instant, modifier: Modifier = Modifier) {
    val label = when {
        isToday(date) -> "Today"
        isYesterday(date) -> "Yesterday"
        else -> dayFormatter.format(date.atZone(ZoneId.systemDefault()))
    }
    
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(Color.Gray.copy(alpha = 0.2f))
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Color.Gray,
            fontSize = 13.sp,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(Color.Gray.copy(alpha = 0.2f))
        )
    }
}

@Composable
private fun ChatBubble(
    message: EventChatMessage,
    isCurrentUser: Boolean,
    showsSenderName: Boolean,
    users: List<User>,
    hostId: String,
    modifier: Modifier = Modifier
) {
    val sender = users.find { 
        it.uid == message.senderId || it.uid == message.senderHandle 
    }
    val isHost = message.senderId == hostId || message.senderHandle == hostId
    
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = if (isCurrentUser) Alignment.End else Alignment.Start
    ) {
        if (!isCurrentUser && showsSenderName) {
            Row(
                modifier = Modifier.padding(start = 8.dp, bottom = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (sender != null) {
                    ProfilePicture(user = sender, size = 20.dp)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = message.senderName,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                    if (isHost) {
                        Text(
                            text = "(host)",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.Gray.copy(alpha = 0.8f),
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = if (isCurrentUser) Arrangement.End else Arrangement.Start
        ) {
            if (isCurrentUser) {
                Spacer(modifier = Modifier.weight(1f))
            }
            
            Column(
                modifier = Modifier
                    .widthIn(max = 240.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(if (isCurrentUser) TealAccent else Color.White)
                    .padding(12.dp),
                horizontalAlignment = if (isCurrentUser) Alignment.End else Alignment.Start,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = message.text,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (isCurrentUser) Color.White else Color.Black,
                    fontSize = 16.sp
                )
                
                Text(
                    text = timeFormatter.format(message.createdAt.atZone(ZoneId.systemDefault())),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (isCurrentUser) Color.White.copy(alpha = 0.7f) else Color.Gray,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            
            if (!isCurrentUser) {
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun ChatComposer(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    enabled: Boolean
) {
    Column {
        Divider()
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            TextField(
                value = text,
                onValueChange = onTextChange,
                modifier = Modifier
                    .weight(1f)
                    .heightIn(min = 48.dp, max = 120.dp),
                placeholder = { Text("Message") },
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color(0xFFF2F2F7),
                    unfocusedContainerColor = Color(0xFFF2F2F7),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    disabledIndicatorColor = Color.Transparent
                ),
                shape = RoundedCornerShape(20.dp),
                maxLines = 4
            )
            
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(if (enabled) TealAccent else Color(0xFFD1D1D6))
                    .clickable(enabled = enabled) { onSend() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Send",
                    modifier = Modifier.size(18.dp),
                    tint = Color.White
                )
            }
        }
    }
}

@Composable
private fun ProfilePicture(user: User, size: androidx.compose.ui.unit.Dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(Color.LightGray)
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
                    .background(Color.Gray.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = user.fullName.take(1).uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    fontSize = (size.value * 0.4).sp
                )
            }
        }
    }
}

private fun shouldGroupWithPrevious(index: Int, messages: List<EventChatMessage>): Boolean {
    if (index == 0) return false
    val current = messages[index]
    val previous = messages[index - 1]
    
    val currentId = current.senderId.ifEmpty { current.senderHandle }
    val previousId = previous.senderId.ifEmpty { previous.senderHandle }
    
    if (currentId != previousId) return false
    
    val timeDiff = ChronoUnit.SECONDS.between(previous.createdAt, current.createdAt)
    return timeDiff < 120 && isSameDay(current.createdAt, previous.createdAt)
}

private fun shouldShowDayDivider(index: Int, messages: List<EventChatMessage>): Boolean {
    if (messages.isEmpty()) return false
    if (index == 0) return true
    
    val current = messages[index].createdAt
    val previous = messages[index - 1].createdAt
    return !isSameDay(current, previous)
}

private fun isSameDay(date1: Instant, date2: Instant): Boolean {
    val zoneId = ZoneId.systemDefault()
    val localDate1 = date1.atZone(zoneId).toLocalDate()
    val localDate2 = date2.atZone(zoneId).toLocalDate()
    return localDate1 == localDate2
}

private fun isToday(date: Instant): Boolean {
    val zoneId = ZoneId.systemDefault()
    val today = Instant.now().atZone(zoneId).toLocalDate()
    val messageDate = date.atZone(zoneId).toLocalDate()
    return today == messageDate
}

private fun isYesterday(date: Instant): Boolean {
    val zoneId = ZoneId.systemDefault()
    val yesterday = Instant.now().atZone(zoneId).toLocalDate().minusDays(1)
    val messageDate = date.atZone(zoneId).toLocalDate()
    return yesterday == messageDate
}

