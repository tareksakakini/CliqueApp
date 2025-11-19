package com.clique.app.ui.screens.auth

import android.app.Activity
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
        }
    ) {
        TextButton(onClick = onGoToSignUp) {
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
        }
    ) {
        TextButton(onClick = onLogin) {
            Text("Already have an account?", color = MaterialTheme.colorScheme.primary)
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
    footer: @Composable () -> Unit
) {
    var phone by remember { mutableStateOf("") }
    var selectedCountry by remember { mutableStateOf(Country.default) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            subtitle,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(32.dp))
        CountryPickerField(selectedCountry = selectedCountry, onCountrySelected = { selectedCountry = it })
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = phone,
            onValueChange = { input -> phone = input.filter { it.isDigit() } },
            label = { Text("Phone Number") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = androidx.compose.ui.text.input.KeyboardType.Number),
            colors = TextFieldDefaults.outlinedTextFieldColors()
        )
        if (!errorMessage.isNullOrBlank()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(errorMessage, color = MaterialTheme.colorScheme.error)
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = { onSubmit(phone, selectedCountry) },
            enabled = !isSending && phone.length >= 6,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            colors = ButtonDefaults.buttonColors()
        ) {
            Text(buttonLabel)
        }
        Spacer(modifier = Modifier.height(16.dp))
        footer()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CountryPickerField(
    selectedCountry: Country,
    onCountrySelected: (Country) -> Unit
) {
    var showDialog by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = "${selectedCountry.flag} ${selectedCountry.name} (${selectedCountry.dialCode})",
        onValueChange = {},
        label = { Text("Country") },
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showDialog = true },
        readOnly = true,
        trailingIcon = { Icon(Icons.Default.ArrowDropDown, contentDescription = null) }
    )

    if (showDialog) {
        var query by remember { mutableStateOf("") }
        val countries = remember(query) {
            if (query.isBlank()) Country.all else Country.all.filter {
                it.name.contains(query, ignoreCase = true) ||
                    PhoneNumberFormatter.digitsOnly(it.dialCode).contains(query)
            }
        }
        AlertDialog(
            onDismissRequest = { showDialog = false },
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
                                        showDialog = false
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
}
