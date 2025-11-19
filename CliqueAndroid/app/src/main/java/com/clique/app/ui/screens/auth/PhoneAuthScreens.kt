package com.clique.app.ui.screens.auth

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clique.app.core.util.PhoneNumberFormatter
import com.clique.app.data.model.Country
import com.clique.app.ui.state.AuthMode
import com.clique.app.ui.state.VerificationUiState

@Composable
fun LoginScreen(
    state: VerificationUiState,
    onSendCode: (Activity, String, Country) -> Unit,
    onNavigateToVerification: (String, String, AuthMode) -> Unit,
    onGoToSignUp: () -> Unit
) {
    val context = LocalContext.current
    PhoneAuthScreen(
        title = "Welcome Back",
        subtitle = "Sign in to plan your next outing",
        buttonLabel = if (state.isSendingCode && state.mode == AuthMode.SIGN_IN) "Sending Code..." else "Continue",
        isSending = state.isSendingCode && state.mode == AuthMode.SIGN_IN,
        errorMessage = if (state.mode == AuthMode.SIGN_IN) state.errorMessage else null,
        onSubmit = { raw, country ->
            val activity = context as? Activity ?: return@PhoneAuthScreen
            onSendCode(activity, raw, country)
        },
        footerPrompt = "Don't have an account?"
    ) {
        TextButton(onClick = onGoToSignUp, contentPadding = PaddingValues(horizontal = 0.dp, vertical = 0.dp)) {
            Text("Create Account", color = MaterialTheme.colorScheme.primary)
        }
    }

    LaunchedEffect(state.verificationId, state.mode) {
        val id = state.verificationId ?: return@LaunchedEffect
        if (!state.isSendingCode && state.mode == AuthMode.SIGN_IN) {
            onNavigateToVerification(id, state.phoneNumber, AuthMode.SIGN_IN)
        }
    }
}

@Composable
fun SignUpScreen(
    state: VerificationUiState,
    onSendCode: (Activity, String, Country) -> Unit,
    onNavigateToVerification: (String, String, AuthMode) -> Unit,
    onLogin: () -> Unit
) {
    val context = LocalContext.current
    PhoneAuthScreen(
        title = "Create Account",
        subtitle = "Enter your phone number to get started",
        buttonLabel = if (state.isSendingCode && state.mode == AuthMode.SIGN_UP) "Sending Code..." else "Continue",
        isSending = state.isSendingCode && state.mode == AuthMode.SIGN_UP,
        errorMessage = if (state.mode == AuthMode.SIGN_UP) state.errorMessage else null,
        onSubmit = { raw, country ->
            val activity = context as? Activity ?: return@PhoneAuthScreen
            onSendCode(activity, raw, country)
        },
        footerPrompt = "Already have an account?"
    ) {
        TextButton(onClick = onLogin, contentPadding = PaddingValues(horizontal = 0.dp, vertical = 0.dp)) {
            Text("Log In", color = MaterialTheme.colorScheme.primary)
        }
    }

    LaunchedEffect(state.verificationId, state.mode) {
        val id = state.verificationId ?: return@LaunchedEffect
        if (!state.isSendingCode && state.mode == AuthMode.SIGN_UP) {
            onNavigateToVerification(id, state.phoneNumber, AuthMode.SIGN_UP)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PhoneAuthScreen(
    title: String,
    subtitle: String,
    buttonLabel: String,
    isSending: Boolean,
    errorMessage: String?,
    onSubmit: (String, Country) -> Unit,
    footerPrompt: String,
    footer: @Composable () -> Unit
) {
    var phone by remember { mutableStateOf("") }
    var selectedCountry by remember { mutableStateOf(Country.default) }

    var showCountryDialog by remember { mutableStateOf(false) }

    val backgroundBrush = remember {
        Brush.verticalGradient(
            colors = listOf(Color(0xFFF3F5FB), Color(0xFFF8F8FA)),
            startY = 0f,
            endY = 1200f
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(backgroundBrush)
            .padding(horizontal = 24.dp, vertical = 32.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            Text(title, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                subtitle,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = Color(0xFF6F757D)
            )
            Spacer(modifier = Modifier.height(32.dp))
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(28.dp),
                shadowElevation = 10.dp,
                tonalElevation = 0.dp,
                color = Color.White
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 24.dp)
                ) {
                    Text("Phone Number", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        CountryCodeSelector(
                            selectedCountry = selectedCountry,
                            onClick = { showCountryDialog = true }
                        )
                        OutlinedTextField(
                            value = phone,
                            onValueChange = { input -> phone = input.filter { it.isDigit() } },
                            modifier = Modifier.weight(1f),
                            placeholder = {
                                Text(
                                    text = "Enter your mobile number",
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    fontSize = 16.sp
                                )
                            },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Phone,
                                    contentDescription = null,
                                    tint = Color(0xFFB0B6BD)
                                )
                            },
                            singleLine = true,
                            shape = RoundedCornerShape(18.dp),
                            keyboardOptions = KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Number),
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                containerColor = Color(0xFFF7F7F9),
                                focusedBorderColor = Color(0xFFB4C7CE),
                                unfocusedBorderColor = Color(0xFFE3E6EA),
                                cursorColor = MaterialTheme.colorScheme.primary
                            )
                        )
                    }
                    if (!errorMessage.isNullOrBlank()) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(errorMessage, color = MaterialTheme.colorScheme.error)
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Start,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(footerPrompt, color = Color(0xFF7C8089))
                        Spacer(modifier = Modifier.width(6.dp))
                        footer()
                    }
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            val canSubmit = !isSending && phone.length >= 6
            GradientButton(
                label = buttonLabel,
                enabled = canSubmit,
                onClick = { onSubmit(phone, selectedCountry) }
            )
        }
    }

    if (showCountryDialog) {
        CountryPickerDialog(
            onDismiss = { showCountryDialog = false },
            onCountrySelected = {
                selectedCountry = it
                showCountryDialog = false
            }
        )
    }
}

@Composable
private fun GradientButton(
    label: String,
    enabled: Boolean,
    onClick: () -> Unit
) {
    val activeBrush = Brush.horizontalGradient(
        listOf(Color(0xFF8FC7A5), Color(0xFF7CBDA5))
    )
    val disabledBrush = Brush.horizontalGradient(
        listOf(Color(0xFFE4ECE7), Color(0xFFD8E2DB))
    )
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clip(RoundedCornerShape(26.dp))
            .background(if (enabled) activeBrush else disabledBrush),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
            disabledContainerColor = Color.Transparent,
            contentColor = Color.White
        ),
        contentPadding = PaddingValues()
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                imageVector = Icons.Filled.ArrowForward,
                contentDescription = null,
                tint = Color.White
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(label, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun CountryCodeSelector(
    selectedCountry: Country,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .width(92.dp)
            .height(56.dp)
            .clip(RoundedCornerShape(18.dp))
            .border(
                width = 1.dp,
                color = Color(0xFFE3E5EA),
                shape = RoundedCornerShape(18.dp)
            )
            .background(Color(0xFFF7F7F9))
            .clickable { onClick() }
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = selectedCountry.dialCode,
            fontWeight = FontWeight.SemiBold
        )
        Icon(
            imageVector = Icons.Default.ArrowDropDown,
            contentDescription = null,
            tint = Color(0xFF9BA1A7)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CountryPickerDialog(
    onDismiss: () -> Unit,
    onCountrySelected: (Country) -> Unit
) {
    var query by remember { mutableStateOf("") }
    val countries = remember(query) {
        if (query.isBlank()) Country.all else Country.all.filter {
            it.name.contains(query, ignoreCase = true) ||
                PhoneNumberFormatter.digitsOnly(it.dialCode).contains(query)
        }
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        title = { Text("Select Country") },
        text = {
            Column {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Search") }
                )
                Spacer(modifier = Modifier.height(12.dp))
                LazyColumn(modifier = Modifier.height(320.dp)) {
                    items(countries) { country ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    onCountrySelected(country)
                                }
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "${country.flag} ${country.name}",
                                modifier = Modifier.weight(1f)
                            )
                            Text(country.dialCode, style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
        }
    )
}
