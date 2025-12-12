package com.yallaconnect.app.ui.screens.settings

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.delay
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import coil.compose.AsyncImage
import com.yallaconnect.app.data.model.User
import com.yallaconnect.app.ui.state.DeleteAccountResult
import com.yallaconnect.app.ui.state.UpdateResult
import com.yallaconnect.app.ui.theme.CliqueCardStroke
import com.yallaconnect.app.ui.theme.CliqueMutedText
import com.yallaconnect.app.ui.theme.CliquePrimary
import com.yallaconnect.app.ui.theme.CliqueSecondary
import com.yallaconnect.app.ui.theme.CliqueSurface
import com.yallaconnect.app.ui.theme.CliqueSurfaceHighlight

@Composable
fun SettingsScreen(
    user: User?,
    onUpdateFullName: (String, (UpdateResult) -> Unit) -> Unit,
    onUpdateUsername: (String, (UpdateResult) -> Unit) -> Unit,
    onDeleteAccount: ((DeleteAccountResult) -> Unit) -> Unit,
    onUploadProfilePhoto: (ByteArray, (UpdateResult) -> Unit) -> Unit,
    onRemoveProfilePhoto: ((UpdateResult) -> Unit) -> Unit,
    onSignOut: () -> Unit,
    onCheckUsernameAvailability: ((String, String?, (Boolean) -> Unit) -> Unit)? = null
) {
    if (user == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
        Text("Please sign in")
        }
        return
    }

    var showEditFullNameDialog by remember { mutableStateOf(false) }
    var showEditUsernameDialog by remember { mutableStateOf(false) }
    var showDeleteAccountDialog by remember { mutableStateOf(false) }
    var showProfilePictureOptionsDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    
    // Capture the callback to avoid shadowing
    val checkUsernameCallback = onCheckUsernameAvailability
    
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            try {
                val inputStream = context.contentResolver.openInputStream(it)
                val imageBytes = inputStream?.readBytes()
                inputStream?.close()
                if (imageBytes != null) {
                    onUploadProfilePhoto(imageBytes) { result ->
                        when (result) {
                            is UpdateResult.Success -> {
                                errorMessage = null
                            }
                            is UpdateResult.Error -> {
                                errorMessage = result.message
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                errorMessage = "Failed to load image: ${e.localizedMessage}"
            }
        }
    }

    Column(
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
            .verticalScroll(rememberScrollState())
            .padding(vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header Section
        Text(
            text = "My Profile",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = CliqueSecondary
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Manage your account and preferences",
            style = MaterialTheme.typography.bodyMedium,
            color = CliqueMutedText
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Profile Picture
        Box(
            contentAlignment = Alignment.BottomEnd
        ) {
            // Profile picture
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(CliqueSurfaceHighlight)
                    .border(1.dp, CliqueCardStroke, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                if (user.profilePic.isNotEmpty() && user.profilePic != "userDefault") {
                    AsyncImage(
                        model = user.profilePic,
                        contentDescription = "Profile Picture",
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Icon(
                        imageVector = Icons.Outlined.AccountCircle,
                        contentDescription = "Profile Picture",
                        modifier = Modifier.size(80.dp),
                        tint = CliqueMutedText
                    )
                }
            }
            
            // Camera icon overlay
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(CliqueSurfaceHighlight)
                    .border(1.dp, CliqueCardStroke, CircleShape)
                    .clickable { showProfilePictureOptionsDialog = true },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CameraAlt,
                    contentDescription = "Change Photo",
                    modifier = Modifier.size(20.dp),
                    tint = CliquePrimary
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // User's display name
        Text(
            text = user.fullName,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = CliqueSecondary
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Profile Information Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            border = BorderStroke(1.dp, CliqueCardStroke)
        ) {
            Column(
                modifier = Modifier.padding(20.dp)
            ) {
                // Full Name
                ProfileInfoItem(
                    icon = Icons.Outlined.Person,
                    label = "FULL NAME",
                    value = user.fullName,
                    showEditIcon = true,
                    onEditClick = { showEditFullNameDialog = true }
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Username
                ProfileInfoItem(
                    icon = Icons.Outlined.AccountCircle,
                    label = "USERNAME",
                    value = user.username,
                    showEditIcon = true,
                    valuePrefix = "@",
                    onEditClick = { showEditUsernameDialog = true }
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Phone Number
                ProfileInfoItem(
                    icon = Icons.Default.Phone,
                    label = "PHONE NUMBER",
                    value = user.phoneNumber,
                    showEditIcon = false
                )
                
                Spacer(modifier = Modifier.height(20.dp))
                
                // Gender
                ProfileInfoItem(
                    icon = Icons.Default.Person,
                    label = "GENDER",
                    value = user.gender.replaceFirstChar { it.uppercase() },
                    showEditIcon = false
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Sign Out Button
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .clickable { onSignOut() },
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = CliqueSurfaceHighlight),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            border = BorderStroke(1.dp, CliqueCardStroke)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
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
                            imageVector = Icons.Default.ExitToApp,
                            contentDescription = "Sign Out",
                            tint = CliquePrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Text(
                        text = "Sign Out",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        color = CliqueSecondary
                    )
                }
                
                Icon(
                    imageVector = Icons.Default.ExitToApp,
                    contentDescription = null,
                    tint = CliqueMutedText,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Delete Account Button
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .clickable { showDeleteAccountDialog = true },
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFFFEDEF)),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
            border = BorderStroke(1.dp, Color(0xFFFFC8CE))
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFFFD6DB)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Delete Account",
                            tint = Color(0xFFD32F2F),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Text(
                        text = "Delete Account",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFFD32F2F)
                    )
                }
                
                Icon(
                    imageVector = Icons.Default.ExitToApp,
                    contentDescription = null,
                    tint = Color(0xFFD32F2F).copy(alpha = 0.5f),
                    modifier = Modifier.size(20.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
    }
    
    // Edit Full Name Dialog
    if (showEditFullNameDialog) {
        EditFullNameDialog(
            currentName = user.fullName,
            onDismiss = { showEditFullNameDialog = false },
            onSave = { newName ->
                onUpdateFullName(newName) { result ->
                    when (result) {
                        is UpdateResult.Success -> {
                            showEditFullNameDialog = false
                            errorMessage = null
                        }
                        is UpdateResult.Error -> {
                            errorMessage = result.message
                        }
                    }
                }
            }
        )
    }
    
    // Edit Username Dialog
    if (showEditUsernameDialog) {
        EditUsernameDialog(
            currentUsername = user.username,
            onDismiss = { 
                showEditUsernameDialog = false
                errorMessage = null
            },
            onSave = { newUsername ->
                onUpdateUsername(newUsername) { result ->
                    when (result) {
                        is UpdateResult.Success -> {
                            showEditUsernameDialog = false
                            errorMessage = null
                        }
                        is UpdateResult.Error -> {
                            errorMessage = result.message
                        }
                    }
                }
            },
            errorMessage = errorMessage,
            onCheckUsernameAvailability = { username, excludeUid, callback ->
                // If username is the same as current, it's available
                if (username.lowercase().trim() == user.username.lowercase().trim()) {
                    callback(true)
                } else if (checkUsernameCallback != null) {
                    // Check availability excluding current user
                    checkUsernameCallback(username, user.uid, callback)
                } else {
                    callback(false)
                }
            },
            currentUserUid = user.uid
        )
    }
    
    // Delete Account Confirmation Dialog
    if (showDeleteAccountDialog) {
        DeleteAccountDialog(
            onDismiss = { showDeleteAccountDialog = false },
            onConfirm = {
                onDeleteAccount { result ->
                    when (result) {
                        is DeleteAccountResult.Success -> {
                            showDeleteAccountDialog = false
                        }
                        is DeleteAccountResult.Error -> {
                            errorMessage = result.message
                            showDeleteAccountDialog = false
                        }
                    }
                }
            }
        )
    }
    
    // Profile Picture Options Dialog
    if (showProfilePictureOptionsDialog) {
        ProfilePictureOptionsDialog(
            hasProfilePicture = user.profilePic.isNotEmpty() && user.profilePic != "userDefault",
            onDismiss = { showProfilePictureOptionsDialog = false },
            onSelectImage = {
                showProfilePictureOptionsDialog = false
                imagePickerLauncher.launch("image/*")
            },
            onRemovePicture = {
                showProfilePictureOptionsDialog = false
                onRemoveProfilePhoto { result ->
                    when (result) {
                        is UpdateResult.Success -> {
                            errorMessage = null
                        }
                        is UpdateResult.Error -> {
                            errorMessage = result.message
                        }
                    }
                }
            }
        )
    }
}

@Composable
private fun ProfileInfoItem(
    icon: ImageVector,
    label: String,
    value: String,
    showEditIcon: Boolean,
    valuePrefix: String = "",
    onEditClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(CliqueSurfaceHighlight),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = CliquePrimary,
                modifier = Modifier.size(20.dp)
            )
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        // Label and Value
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = CliqueMutedText,
                fontSize = 11.sp,
                letterSpacing = 0.5.sp
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = "$valuePrefix$value",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                color = CliqueSecondary
            )
        }
        
        // Edit Icon
        if (showEditIcon && onEditClick != null) {
            IconButton(
                onClick = onEditClick,
                modifier = Modifier.size(40.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Edit,
                    contentDescription = "Edit",
                    tint = CliqueMutedText,
                    modifier = Modifier.size(20.dp)
                )
            }
        } else if (showEditIcon) {
            Icon(
                imageVector = Icons.Default.Edit,
                contentDescription = "Edit",
                tint = CliqueMutedText,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun EditFullNameDialog(
    currentName: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit
) {
    var name by remember { mutableStateOf(currentName) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Full Name") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Full Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (name.isNotBlank()) {
                        onSave(name.trim())
                    }
                },
                enabled = name.isNotBlank() && name.trim() != currentName
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

private enum class UsernameAvailabilityStatus {
    None,
    Checking,
    Available,
    Taken
}

@Composable
private fun EditUsernameDialog(
    currentUsername: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
    errorMessage: String?,
    onCheckUsernameAvailability: ((String, String?, (Boolean) -> Unit) -> Unit)? = null,
    currentUserUid: String? = null
) {
    var username by remember { mutableStateOf(currentUsername) }
    var usernameAvailabilityStatus by remember { mutableStateOf<UsernameAvailabilityStatus>(UsernameAvailabilityStatus.None) }
    
    // Debounced username availability check
    LaunchedEffect(username) {
        val trimmed = username.trim().lowercase()
        val currentTrimmed = currentUsername.trim().lowercase()
        
        // If username is the same as current, it's available
        if (trimmed == currentTrimmed) {
            usernameAvailabilityStatus = UsernameAvailabilityStatus.Available
            return@LaunchedEffect
        }
        
        if (trimmed.length < 3) {
            usernameAvailabilityStatus = UsernameAvailabilityStatus.None
            return@LaunchedEffect
        }
        
        usernameAvailabilityStatus = UsernameAvailabilityStatus.Checking
        delay(500) // Debounce 500ms
        
        // Only check if username hasn't changed during delay
        if (username.trim().lowercase() == trimmed && onCheckUsernameAvailability != null) {
            onCheckUsernameAvailability(trimmed, currentUserUid) { isAvailable ->
                // Only update if username still matches
                if (username.trim().lowercase() == trimmed) {
                    usernameAvailabilityStatus = if (isAvailable) {
                        UsernameAvailabilityStatus.Available
                    } else {
                        UsernameAvailabilityStatus.Taken
                    }
                }
            }
        }
    }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Username") },
        text = {
            Column {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it.lowercase().filter { char -> char.isLetterOrDigit() || char == '_' } },
                    label = { Text("Username") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    isError = errorMessage != null || usernameAvailabilityStatus == UsernameAvailabilityStatus.Taken,
                    colors = androidx.compose.material3.OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = when (usernameAvailabilityStatus) {
                            UsernameAvailabilityStatus.Available -> Color(0xFF4CAF50)
                            UsernameAvailabilityStatus.Taken -> MaterialTheme.colorScheme.error
                            else -> MaterialTheme.colorScheme.primary
                        },
                        unfocusedBorderColor = when (usernameAvailabilityStatus) {
                            UsernameAvailabilityStatus.Available -> Color(0xFF4CAF50)
                            UsernameAvailabilityStatus.Taken -> MaterialTheme.colorScheme.error
                            else -> MaterialTheme.colorScheme.outline
                        }
                    ),
                    supportingText = {
                        when {
                            errorMessage != null -> {
                                Text(errorMessage!!, color = Color(0xFFD32F2F))
                            }
                            usernameAvailabilityStatus == UsernameAvailabilityStatus.Checking -> {
                                Text("Checking availability...", color = CliqueMutedText, fontSize = 12.sp)
                            }
                            usernameAvailabilityStatus == UsernameAvailabilityStatus.Available -> {
                                Text("Username is available", color = Color(0xFF4CAF50), fontSize = 12.sp)
                            }
                            usernameAvailabilityStatus == UsernameAvailabilityStatus.Taken -> {
                                Text("Username is already taken", color = MaterialTheme.colorScheme.error, fontSize = 12.sp)
                            }
                            username.isNotBlank() && username.length < 3 -> {
                                Text("Username must be at least 3 characters", color = CliqueMutedText, fontSize = 12.sp)
                            }
                            else -> null
                        }
                    }
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val trimmed = username.trim()
                    if (trimmed.isNotBlank() && trimmed != currentUsername) {
                        onSave(trimmed)
                    }
                },
                enabled = username.isNotBlank() && 
                    username.trim() != currentUsername && 
                    usernameAvailabilityStatus == UsernameAvailabilityStatus.Available
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun DeleteAccountDialog(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Delete Account", color = Color(0xFFD32F2F)) },
        text = {
            Text(
                "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted."
            )
        },
        confirmButton = {
            Button(
                onClick = onConfirm,
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFD32F2F)
                )
            ) {
                Text("Delete", color = Color.White)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun ProfilePictureOptionsDialog(
    hasProfilePicture: Boolean,
    onDismiss: () -> Unit,
    onSelectImage: () -> Unit,
    onRemovePicture: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Profile Picture") },
        text = {
            Column {
                if (hasProfilePicture) {
                    TextButton(
                        onClick = onSelectImage,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Change Picture")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    TextButton(
                        onClick = onRemovePicture,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Remove Picture", color = Color(0xFFD32F2F))
                    }
                } else {
                    TextButton(
                        onClick = onSelectImage,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Add Picture")
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
