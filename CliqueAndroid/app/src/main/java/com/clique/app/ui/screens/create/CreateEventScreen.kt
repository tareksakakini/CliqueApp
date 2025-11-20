package com.clique.app.ui.screens.create

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.util.Log
import android.widget.Toast
import coil.compose.AsyncImage
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Calendar
import java.time.ZonedDateTime

private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")
private val timeFormatter = DateTimeFormatter.ofPattern("h:mm a")
private val greenAccent = Color(0xFF6BBFA8)

@Composable
fun CreateEventScreen(
    user: User?,
    users: List<User> = emptyList(),
    friendships: List<String> = emptyList(),
    onSave: (Event, ByteArray?) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var start by remember { mutableStateOf(LocalDateTime.now()) }
    var end by remember { mutableStateOf(LocalDateTime.now().plusHours(2)) }
    var noEndTime by remember { mutableStateOf(false) }
    var selectedImageUri by remember { mutableStateOf<android.net.Uri?>(null) }
    var selectedImageBytes by remember { mutableStateOf<ByteArray?>(null) }
    var showAddInviteesDialog by remember { mutableStateOf(false) }
    var selectedInvitees by remember { mutableStateOf<List<String>>(emptyList()) }
    var isSaving by remember { mutableStateOf(false) }
    var saveSuccess by remember { mutableStateOf(false) }
    var showErrorDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    val coroutineScope = rememberCoroutineScope()
    
    // Clear form after successful save
    LaunchedEffect(saveSuccess) {
        if (saveSuccess) {
            title = ""
            location = ""
            description = ""
            start = LocalDateTime.now()
            end = LocalDateTime.now().plusHours(2)
            noEndTime = false
            selectedImageUri = null
            selectedImageBytes = null
            selectedInvitees = emptyList()
            isSaving = false
            saveSuccess = false
        }
    }
    
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            selectedImageUri = it
            try {
                val inputStream = context.contentResolver.openInputStream(it)
                selectedImageBytes = inputStream?.readBytes()
                inputStream?.close()
            } catch (e: Exception) {
                selectedImageBytes = null
            }
        }
    }
    
    fun pickDate(initial: LocalDateTime, onDateSelected: (LocalDateTime) -> Unit) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.YEAR, initial.year)
            set(Calendar.MONTH, initial.monthValue - 1)
            set(Calendar.DAY_OF_MONTH, initial.dayOfMonth)
        }
        DatePickerDialog(
            context,
            { _, year, month, day ->
                val newDate = initial.withYear(year).withMonth(month + 1).withDayOfMonth(day)
                onDateSelected(newDate)
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        ).show()
    }
    
    fun pickTime(initial: LocalDateTime, onTimeSelected: (LocalDateTime) -> Unit) {
        TimePickerDialog(
            context,
            { _, hour, minute ->
                val newTime = initial.withHour(hour).withMinute(minute)
                onTimeSelected(newTime)
            },
            initial.hour,
            initial.minute,
            false
        ).show()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5))
            .verticalScroll(scrollState)
    ) {
        // Header
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Create Event",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                fontSize = 32.sp,
                color = Color.Black
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Plan something amazing with your friends",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray,
                fontSize = 16.sp
            )
        }
        
        // Main Content Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp)
            ) {
                // Event Photo Section
                Text(
                    text = "Event Photo",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFFF5F5F5))
                        .clickable { imagePickerLauncher.launch("image/*") },
                    contentAlignment = Alignment.Center
                ) {
                    if (selectedImageUri != null) {
                        AsyncImage(
                            model = selectedImageUri,
                            contentDescription = "Event Photo",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = "Add Photo",
                                modifier = Modifier.size(48.dp),
                                tint = greenAccent
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Add Event Picture",
                                color = greenAccent,
                                fontWeight = FontWeight.Medium,
                                fontSize = 16.sp
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Event Title
                Text(
                    text = "Event Title",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
                    placeholder = { Text("Aa What's the event called?") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Transparent,
                        unfocusedBorderColor = Color.Transparent,
                        focusedContainerColor = Color(0xFFF5F5F5),
                        unfocusedContainerColor = Color(0xFFF5F5F5)
                    )
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Location
                Text(
                    text = "Location",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = Color.Black
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = location,
            onValueChange = { location = it },
                    placeholder = { Text("Search for a location...") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = "Location",
                            tint = Color.Gray
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Transparent,
                        unfocusedBorderColor = Color.Transparent,
                        focusedContainerColor = Color(0xFFF5F5F5),
                        unfocusedContainerColor = Color(0xFFF5F5F5)
                    )
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Description
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Description",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = Color.Black
                    )
                    Text(
                        text = "${description.length}/1000",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray,
                        fontSize = 14.sp
                    )
                }
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = description,
                    onValueChange = { if (it.length <= 1000) description = it },
                    placeholder = { Text("Tell your friends more about this event...") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    maxLines = 5,
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color.Transparent,
                        unfocusedBorderColor = Color.Transparent,
                        focusedContainerColor = Color(0xFFF5F5F5),
                        unfocusedContainerColor = Color(0xFFF5F5F5)
                    )
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Starts
                Text(
                    text = "Starts",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    TextButton(
                        onClick = { pickDate(start) { start = it } },
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = androidx.compose.material3.ButtonDefaults.textButtonColors(
                            containerColor = Color(0xFFF5F5F5),
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            text = dateFormatter.format(start),
                            fontWeight = FontWeight.Medium
                        )
                    }
                    TextButton(
                        onClick = { pickTime(start) { start = it } },
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = androidx.compose.material3.ButtonDefaults.textButtonColors(
                            containerColor = Color(0xFFF5F5F5),
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            text = timeFormatter.format(start),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // No End Time Checkbox
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = noEndTime,
                        onCheckedChange = { noEndTime = it }
                    )
                    Text(
                        text = "This event doesn't have an end time",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.Black
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Ends (only show if noEndTime is false)
                if (!noEndTime) {
                    Text(
                        text = "Ends",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = Color.Black
        )
        Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        TextButton(
                            onClick = { pickDate(end) { end = it } },
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = androidx.compose.material3.ButtonDefaults.textButtonColors(
                                containerColor = Color(0xFFF5F5F5),
                                contentColor = Color.Black
                            )
                        ) {
                            Text(
                                text = dateFormatter.format(end),
                                fontWeight = FontWeight.Medium
                            )
                        }
                        TextButton(
                            onClick = { pickTime(end) { end = it } },
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = androidx.compose.material3.ButtonDefaults.textButtonColors(
                                containerColor = Color(0xFFF5F5F5),
                                contentColor = Color.Black
                            )
                        ) {
                            Text(
                                text = timeFormatter.format(end),
                                fontWeight = FontWeight.Medium
                            )
                        }
        }
        Spacer(modifier = Modifier.height(24.dp))
                } else {
                    Spacer(modifier = Modifier.height(24.dp))
                }
                
                // Invitees Section
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Invitees",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = Color.Black
                    )
                    Button(
                        onClick = { showAddInviteesDialog = true },
                        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                            containerColor = greenAccent
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.height(40.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PersonAdd,
                            contentDescription = "Add People",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Add People",
                            fontWeight = FontWeight.Medium,
                            fontSize = 14.sp
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                
                // Invitees Placeholder or List
                if (selectedInvitees.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(120.dp)
                            .border(
                                width = 2.dp,
                                color = Color(0xFFE0E0E0),
                                shape = RoundedCornerShape(12.dp)
                            )
                            .clip(RoundedCornerShape(12.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.PersonAdd,
                                contentDescription = "No Invitees",
                                modifier = Modifier.size(40.dp),
                                tint = Color.Gray
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "No invitees yet",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.Gray
                            )
                            Text(
                                text = "Tap 'Add People' to invite friends",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.Gray,
                                fontSize = 12.sp
                            )
                        }
                    }
                } else {
                    val selectedUsers = users.filter { selectedInvitees.contains(it.uid) }
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(120.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFFF5F5F5))
                            .padding(8.dp)
                    ) {
                        items(selectedUsers) { user ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(Color(0xFFE0E0E0)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Person,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp),
                                        tint = Color.Gray
                                    )
                                }
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = user.fullName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color.Black
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(32.dp))
                
                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = {
                            Log.d("CreateEvent", "Cancel button clicked")
                            // Clear form
                            title = ""
                            location = ""
                            description = ""
                            start = LocalDateTime.now()
                            end = LocalDateTime.now().plusHours(2)
                            noEndTime = false
                            selectedImageUri = null
                            selectedImageBytes = null
                            selectedInvitees = emptyList()
                            Toast.makeText(context, "Form cleared", Toast.LENGTH_SHORT).show()
                        },
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFE0E0E0),
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            text = "Cancel",
                            fontWeight = FontWeight.Medium
                        )
                    }
                    Button(
                        onClick = {
                            Log.d("CreateEvent", "Create Event button clicked - title: $title, location: $location, isSaving: $isSaving")
                            
                            // Validation
                            val validationError = validateEvent(
                                title = title,
                                location = location,
                                startDateTime = start,
                                endDateTime = end,
                                noEndTime = noEndTime
                            )
                            
                            if (validationError != null) {
                                errorMessage = validationError
                                showErrorDialog = true
                                return@Button
                            }
                            
                            if (!isSaving) {
                                isSaving = true
                                val event = Event(
                                    title = title,
                                    location = location,
                                    description = description,
                                    startDateTime = start.atZone(ZoneId.systemDefault()).toInstant(),
                                    endDateTime = if (noEndTime) start.atZone(ZoneId.systemDefault()).toInstant() else end.atZone(ZoneId.systemDefault()).toInstant(),
                                    noEndTime = noEndTime,
                                    attendeesInvited = selectedInvitees,
                                    attendeesAccepted = emptyList(), // Host is not included in attendees
                                    host = user?.uid ?: ""
                                )
                                Log.d("CreateEvent", "Calling onSave with event: ${event.title}")
                                onSave(event, selectedImageBytes)
                                Toast.makeText(context, "Event created successfully!", Toast.LENGTH_SHORT).show()
                                // Mark as successful after a short delay to allow save to process
                                coroutineScope.launch {
                                    kotlinx.coroutines.delay(500)
                                    saveSuccess = true
                                }
                            }
                        },
                        enabled = !isSaving,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                            containerColor = greenAccent
                        )
                    ) {
                        if (isSaving) {
                            androidx.compose.material3.CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                text = "Create Event",
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
    }
    
    // Add Invitees Dialog
    if (showAddInviteesDialog) {
        AddInviteesDialog(
            users = users,
            friendships = friendships,
            currentUserId = user?.uid,
            selectedInvitees = selectedInvitees,
            onDismiss = { showAddInviteesDialog = false },
            onInviteesSelected = { invitees ->
                selectedInvitees = invitees
                showAddInviteesDialog = false
            }
        )
    }
    
    // Error Dialog
    if (showErrorDialog && errorMessage != null) {
        AlertDialog(
            onDismissRequest = { 
                showErrorDialog = false
                errorMessage = null
            },
            title = { 
                Text(
                    "Cannot Create Event",
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFD32F2F)
                )
            },
            text = { 
                Text(errorMessage!!)
            },
            confirmButton = {
                Button(
                    onClick = { 
                        showErrorDialog = false
                        errorMessage = null
                    },
                    colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFD32F2F)
                    )
                ) {
                    Text("OK")
                }
            }
        )
    }
}

private fun validateEvent(
    title: String,
    location: String,
    startDateTime: LocalDateTime,
    endDateTime: LocalDateTime,
    noEndTime: Boolean
): String? {
    // Check title length
    if (title.trim().length <= 3) {
        return "Event title must be longer than 3 characters."
    }
    
    // Check location
    if (location.isBlank()) {
        return "Please provide a location for the event."
    }
    
    // Check if start time is in the past
    val now = LocalDateTime.now()
    if (startDateTime.isBefore(now)) {
        return "The event start date and time cannot be in the past."
    }
    
    // Check if end time is before start time (only if end time is set)
    if (!noEndTime && endDateTime.isBefore(startDateTime)) {
        return "The end time cannot be before the start time."
    }
    
    return null
}

@Composable
private fun AddInviteesDialog(
    users: List<User>,
    friendships: List<String>,
    currentUserId: String?,
    selectedInvitees: List<String>,
    onDismiss: () -> Unit,
    onInviteesSelected: (List<String>) -> Unit
) {
    val friendsList = remember(users, friendships, currentUserId) {
        users.filter { user ->
            user.uid != currentUserId && friendships.contains(user.uid)
        }
    }
    
    var tempSelected by remember { mutableStateOf(selectedInvitees.toSet()) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add People") },
        text = {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
            ) {
                items(friendsList) { friend ->
                    val isSelected = tempSelected.contains(friend.uid)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                tempSelected = if (isSelected) {
                                    tempSelected - friend.uid
                                } else {
                                    tempSelected + friend.uid
                                }
                            }
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(20.dp))
                                .background(Color(0xFFE0E0E0)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                tint = Color.Gray
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = friend.fullName,
                            modifier = Modifier.weight(1f)
                        )
                        if (isSelected) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = "Selected",
                                tint = greenAccent
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onInviteesSelected(tempSelected.toList()) },
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = greenAccent
                )
            ) {
                Text("Done")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
