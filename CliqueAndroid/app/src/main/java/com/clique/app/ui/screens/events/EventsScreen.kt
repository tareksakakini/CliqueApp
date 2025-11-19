package com.clique.app.ui.screens.events

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
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.clique.app.core.util.PhoneNumberFormatter
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import com.clique.app.data.repository.model.InviteAction
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, h:mm a")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventsScreen(
    user: User?,
    events: List<Event>,
    isInviteScreen: Boolean,
    onRespond: (Event, InviteAction) -> Unit
) {
    var filter by remember { mutableStateOf(if (isInviteScreen) InviteFilter.Pending else InviteFilter.Upcoming) }
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
                when (filter) {
                    InviteFilter.Upcoming -> event.attendeesAccepted.contains(user.uid) || event.host == user.uid
                    InviteFilter.Declined -> event.attendeesDeclined.contains(user.uid)
                    InviteFilter.Past -> event.endDateTime.isBefore(Instant.now())
                    InviteFilter.Pending -> false
                }
            }
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text(
            text = if (isInviteScreen) "My Invites" else "My Events",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(16.dp))
        val options = if (isInviteScreen) listOf(InviteFilter.Pending, InviteFilter.Declined) else listOf(InviteFilter.Upcoming, InviteFilter.Past)
        TabRow(selectedTabIndex = options.indexOf(filter)) {
            options.forEachIndexed { index, option ->
                Tab(
                    selected = filter == option,
                    onClick = { filter = option },
                    text = { Text(option.label) }
                )
            }
        }
        Spacer(modifier = Modifier.height(16.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(filteredEvents) { event ->
                EventCard(event = event, isInviteScreen = isInviteScreen, onRespond = onRespond)
            }
        }
    }
}

@Composable
private fun EventCard(event: Event, isInviteScreen: Boolean, onRespond: (Event, InviteAction) -> Unit) {
    val startTime = dateFormatter.format(event.startDateTime.atZone(ZoneId.systemDefault()))
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(event.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(4.dp))
            Text(event.location, style = MaterialTheme.typography.bodyMedium)
            Text(startTime, style = MaterialTheme.typography.bodySmall)
            if (isInviteScreen) {
                Spacer(modifier = Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    Button(onClick = { onRespond(event, InviteAction.ACCEPT) }, modifier = Modifier.weight(1f)) {
                        Text("Accept")
                    }
                    OutlinedButton(onClick = { onRespond(event, InviteAction.DECLINE) }, modifier = Modifier.weight(1f)) {
                        Text("Decline")
                    }
                }
            }
        }
    }
}

enum class InviteFilter(val label: String) {
    Upcoming("Upcoming"),
    Past("Past"),
    Pending("Pending"),
    Declined("Declined")
}
