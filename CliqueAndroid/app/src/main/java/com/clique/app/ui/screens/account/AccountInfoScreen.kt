package com.clique.app.ui.screens.account

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
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.RadioButton
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
import androidx.compose.foundation.text.ClickableText
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

// Teal color matching iOS design
val TealColor = Color(0xFF20B2AA)
val LightGreenColor = Color(0xFF90EE90)

private enum class UsernameAvailabilityStatus {
    None,
    Checking,
    Available,
    Taken
}

@Composable
fun AccountInfoScreen(
    phoneNumber: String,
    errorMessage: String?,
    isSubmitting: Boolean,
    onSubmit: (String, String, String) -> Unit,
    onViewPolicy: () -> Unit,
    onCheckUsernameAvailability: ((String, (Boolean) -> Unit) -> Unit)? = null
) {
    var fullName by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf("Male") }
    var confirmedAge by remember { mutableStateOf(false) }
    var acceptedPolicy by remember { mutableStateOf(false) }
    
    // Username availability state
    var usernameAvailabilityStatus by remember { mutableStateOf<UsernameAvailabilityStatus>(UsernameAvailabilityStatus.None) }
    
    // Debounced username availability check
    LaunchedEffect(username) {
        val trimmed = username.trim()
        if (trimmed.length < 3) {
            usernameAvailabilityStatus = UsernameAvailabilityStatus.None
            return@LaunchedEffect
        }
        
        usernameAvailabilityStatus = UsernameAvailabilityStatus.Checking
        delay(500) // Debounce 500ms
        
        // Only check if username hasn't changed during delay
        if (username.trim() == trimmed && onCheckUsernameAvailability != null) {
            onCheckUsernameAvailability(trimmed) { isAvailable ->
                // Only update if username still matches
                if (username.trim() == trimmed) {
                    usernameAvailabilityStatus = if (isAvailable) {
                        UsernameAvailabilityStatus.Available
                    } else {
                        UsernameAvailabilityStatus.Taken
                    }
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(32.dp))
        
        // Profile Icon
        Box(
            modifier = Modifier.size(100.dp),
            contentAlignment = Alignment.Center
        ) {
            // Person silhouette
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                modifier = Modifier.size(80.dp),
                tint = TealColor
            )
            // Plus icon overlay
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .align(Alignment.BottomEnd)
                    .background(TealColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color.White
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Title
        Text(
            text = "Complete Your Profile",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Subtitle
        Text(
            text = "Tell us a bit about yourself",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray,
            fontSize = 16.sp
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // White Card Container
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Color.White,
                    RoundedCornerShape(16.dp)
                )
                .padding(20.dp)
        ) {
            // Full Name Input
            Text(
                text = "Full Name",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it },
                placeholder = { Text("Enter your full name", color = Color.Gray) },
                leadingIcon = {
                    Text(
                        text = "Aa",
                        color = Color.Gray,
                        fontSize = 16.sp,
                        modifier = Modifier.padding(start = 4.dp)
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = TealColor,
                    unfocusedBorderColor = Color.LightGray
                )
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            // Username Input
            Text(
                text = "Username",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            OutlinedTextField(
                value = username,
                onValueChange = { username = it.lowercase() },
                placeholder = { Text("Choose a unique username", color = Color.Gray) },
                leadingIcon = {
                    Text(
                        text = "@",
                        color = Color.Gray,
                        fontSize = 16.sp,
                        modifier = Modifier.padding(start = 4.dp)
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = when (usernameAvailabilityStatus) {
                        UsernameAvailabilityStatus.Available -> Color(0xFF4CAF50)
                        UsernameAvailabilityStatus.Taken -> MaterialTheme.colorScheme.error
                        else -> TealColor
                    },
                    unfocusedBorderColor = when (usernameAvailabilityStatus) {
                        UsernameAvailabilityStatus.Available -> Color(0xFF4CAF50)
                        UsernameAvailabilityStatus.Taken -> MaterialTheme.colorScheme.error
                        else -> Color.LightGray
                    },
                    errorBorderColor = MaterialTheme.colorScheme.error
                ),
                isError = usernameAvailabilityStatus == UsernameAvailabilityStatus.Taken,
                supportingText = {
                    when (usernameAvailabilityStatus) {
                        UsernameAvailabilityStatus.Checking -> {
                            Text("Checking availability...", color = Color.Gray, fontSize = 12.sp)
                        }
                        UsernameAvailabilityStatus.Available -> {
                            Text("Username is available", color = Color(0xFF4CAF50), fontSize = 12.sp)
                        }
                        UsernameAvailabilityStatus.Taken -> {
                            Text("Username is already taken", color = MaterialTheme.colorScheme.error, fontSize = 12.sp)
                        }
                        UsernameAvailabilityStatus.None -> {
                            if (username.isNotBlank() && username.length < 3) {
                                Text("Username must be at least 3 characters", color = Color.Gray, fontSize = 12.sp)
                            } else {
                                null
                            }
                        }
                    }
                }
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            // Gender Selection
            Text(
                text = "Gender",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            SegmentedControl(
                options = listOf("Male", "Female", "Other"),
                selected = gender,
                onSelect = { gender = it }
            )
            
            Spacer(modifier = Modifier.height(20.dp))
            
            // Age Confirmation
            CheckboxRow(
                text = "I am 16 years or older",
                checked = confirmedAge,
                onCheckedChange = { confirmedAge = it }
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Privacy Policy Agreement
            PrivacyPolicyCheckboxRow(
                checked = acceptedPolicy,
                onCheckedChange = { acceptedPolicy = it },
                onPolicyClick = onViewPolicy
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Error Message
            if (!errorMessage.isNullOrBlank()) {
                Text(
                    text = errorMessage,
                    color = MaterialTheme.colorScheme.error,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }
            
            // Create Account Button
            val isButtonEnabled = fullName.isNotBlank() && 
                username.length >= 3 && 
                usernameAvailabilityStatus == UsernameAvailabilityStatus.Available &&
                confirmedAge && 
                acceptedPolicy && 
                !isSubmitting
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(
                        brush = if (isButtonEnabled) {
                            Brush.horizontalGradient(
                                colors = listOf(LightGreenColor, TealColor)
                            )
                        } else {
                            Brush.horizontalGradient(
                                colors = listOf(Color.LightGray, Color.Gray)
                            )
                        }
                    )
                    .clickable(enabled = isButtonEnabled) {
                        if (isButtonEnabled) {
                            onSubmit(fullName, username, gender)
                        }
                    },
                contentAlignment = Alignment.Center
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = Color.White
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Color.White
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isSubmitting) "Creating..." else "Create Account",
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun CheckboxRow(text: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) },
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = checked,
            onClick = { onCheckedChange(!checked) }
        )
        Text(
            text = text,
            modifier = Modifier.padding(start = 8.dp),
            fontSize = 15.sp
        )
    }
}

@Composable
private fun PrivacyPolicyCheckboxRow(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    onPolicyClick: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = checked,
            onClick = { onCheckedChange(!checked) }
        )
        val annotatedString = buildAnnotatedString {
            append("I agree to the ")
            pushStringAnnotation(tag = "PrivacyPolicy", annotation = "clickable")
            withStyle(style = SpanStyle(color = Color(0xFF007AFF))) {
                append("Privacy Policy")
            }
            pop()
        }
        androidx.compose.foundation.text.ClickableText(
            text = annotatedString,
            modifier = Modifier.padding(start = 8.dp),
            style = MaterialTheme.typography.bodyMedium.copy(fontSize = 15.sp),
            onClick = { offset ->
                annotatedString.getStringAnnotations(
                    tag = "PrivacyPolicy",
                    start = offset,
                    end = offset
                ).firstOrNull()?.let {
                    onPolicyClick()
                } ?: run {
                    onCheckedChange(!checked)
                }
            }
        )
    }
}

@Composable
private fun SegmentedControl(
    options: List<String>,
    selected: String,
    onSelect: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp)
            .background(Color(0xFFF0F0F0), RoundedCornerShape(8.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        options.forEach { option ->
            val isSelected = selected == option
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxSize()
                    .clip(RoundedCornerShape(6.dp))
                    .background(
                        if (isSelected) Color.White else Color.Transparent
                    )
                    .clickable { onSelect(option) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = option,
                    color = if (isSelected) Color.Black else Color.Gray,
                    fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal,
                    fontSize = 15.sp
                )
            }
        }
    }
}
