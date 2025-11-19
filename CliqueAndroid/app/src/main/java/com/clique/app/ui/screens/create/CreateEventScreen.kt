package com.clique.app.ui.screens.create

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Calendar

private val dateTimeFormatter = DateTimeFormatter.ofPattern("MMM d, h:mm a")

@Composable
fun CreateEventScreen(
    user: User?,
    onSave: (Event) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var start by remember { mutableStateOf(LocalDateTime.now()) }
    var end by remember { mutableStateOf(LocalDateTime.now().plusHours(2)) }
    var showDatePickerForStart by remember { mutableStateOf(false) }
    val context = LocalContext.current

    fun pickDateTime(initial: LocalDateTime, onDateTimeSelected: (LocalDateTime) -> Unit) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.YEAR, initial.year)
            set(Calendar.MONTH, initial.monthValue - 1)
            set(Calendar.DAY_OF_MONTH, initial.dayOfMonth)
        }
        DatePickerDialog(
            context,
            { _, year, month, day ->
                val date = initial.withYear(year).withMonth(month + 1).withDayOfMonth(day)
                TimePickerDialog(
                    context,
                    { _, hour, minute ->
                        onDateTimeSelected(date.withHour(hour).withMinute(minute))
                    },
                    initial.hour,
                    initial.minute,
                    false
                ).show()
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        Text("Create Event", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("Title") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = location,
            onValueChange = { location = it },
            label = { Text("Location") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = description,
            onValueChange = { description = it },
            label = { Text("Description") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(12.dp))
        Button(onClick = { pickDateTime(start) { start = it } }) {
            Text("Start: ${dateTimeFormatter.format(start)}")
        }
        Spacer(modifier = Modifier.height(8.dp))
        Button(onClick = { pickDateTime(end) { end = it } }) {
            Text("End: ${dateTimeFormatter.format(end)}")
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = {
                val event = Event(
                    title = title,
                    location = location,
                    description = description,
                    startDateTime = start.atZone(ZoneId.systemDefault()).toInstant(),
                    endDateTime = end.atZone(ZoneId.systemDefault()).toInstant(),
                    attendeesAccepted = listOfNotNull(user?.uid),
                    host = user?.uid ?: ""
                )
                onSave(event)
            },
            enabled = title.isNotBlank() && location.isNotBlank(),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Save Event")
        }
    }
}
