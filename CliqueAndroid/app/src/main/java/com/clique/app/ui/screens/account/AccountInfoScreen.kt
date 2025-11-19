package com.clique.app.ui.screens.account

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun AccountInfoScreen(
    phoneNumber: String,
    errorMessage: String?,
    isSubmitting: Boolean,
    onSubmit: (String, String, String) -> Unit,
    onViewPolicy: () -> Unit
) {
    var fullName by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf("Male") }
    var confirmedAge by remember { mutableStateOf(false) }
    var acceptedPolicy by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Complete Your Profile", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(8.dp))
        Text("Phone: $phoneNumber")
        Spacer(modifier = Modifier.height(24.dp))
        OutlinedTextField(
            value = fullName,
            onValueChange = { fullName = it },
            label = { Text("Full Name") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = username,
            onValueChange = { username = it.lowercase() },
            label = { Text("Username") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text("Gender", style = MaterialTheme.typography.labelLarge, modifier = Modifier.align(Alignment.Start))
        RowSelect(options = listOf("Male", "Female", "Other"), selected = gender, onSelect = { gender = it })
        Spacer(modifier = Modifier.height(16.dp))
        CheckboxRow(text = "I am 16 years or older", checked = confirmedAge, onCheckedChange = { confirmedAge = it })
        CheckboxRow(text = "I agree to the privacy policy", checked = acceptedPolicy, onCheckedChange = { acceptedPolicy = it })
        TextButton(onClick = onViewPolicy) {
            Text("View privacy policy")
        }
        if (!errorMessage.isNullOrBlank()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(errorMessage, color = MaterialTheme.colorScheme.error)
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = { onSubmit(fullName, username, gender) },
            enabled = fullName.isNotBlank() && username.length >= 3 && confirmedAge && acceptedPolicy && !isSubmitting,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
        ) {
            Text(if (isSubmitting) "Creating..." else "Create Account")
        }
    }
}

@Composable
private fun CheckboxRow(text: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Checkbox(checked = checked, onCheckedChange = onCheckedChange)
        Text(text, modifier = Modifier.padding(start = 8.dp))
    }
}

@Composable
private fun RowSelect(options: List<String>, selected: String, onSelect: (String) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
        options.forEach { option ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.toggleable(value = selected == option, onValueChange = { onSelect(option) })
            ) {
                RadioButton(selected = selected == option, onClick = { onSelect(option) })
                Text(option)
            }
        }
    }
}
