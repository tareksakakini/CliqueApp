package com.clique.app.data.model

import com.clique.app.core.util.PhoneNumberFormatter
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.time.Instant

private fun Timestamp?.toInstantOrNow(): Instant = this?.toDate()?.toInstant() ?: Instant.now()

data class Event(
    val id: String = "",
    val title: String = "",
    val location: String = "",
    val description: String = "",
    val startDateTime: Instant = Instant.now(),
    val endDateTime: Instant = Instant.now(),
    val noEndTime: Boolean = false,
    val attendeesAccepted: List<String> = emptyList(),
    val attendeesInvited: List<String> = emptyList(),
    val attendeesDeclined: List<String> = emptyList(),
    val host: String = "",
    val eventPic: String = "",
    val invitedPhoneNumbers: List<String> = emptyList(),
    val acceptedPhoneNumbers: List<String> = emptyList(),
    val declinedPhoneNumbers: List<String> = emptyList()
) {
    val chatParticipantUserIds: Set<String>
        get() = buildSet {
            if (host.isNotBlank()) add(host)
            attendeesAccepted.filter { it.isNotBlank() }.forEach { add(it) }
            attendeesInvited.filter { it.isNotBlank() }.forEach { add(it) }
            attendeesDeclined.filter { it.isNotBlank() }.forEach { add(it) }
        }

    fun isInviteContextFor(userId: String, phoneNumber: String): Boolean {
        val invitedById = attendeesInvited.contains(userId) || attendeesDeclined.contains(userId)
        val invitedByPhone = phoneNumber.isNotBlank() && invitedPhoneNumbers.any {
            PhoneNumberFormatter.numbersMatch(it, phoneNumber)
        }
        return invitedById || invitedByPhone
    }

    companion object {
        fun fromSnapshot(snapshot: DocumentSnapshot): Event {
            val data = snapshot.data ?: emptyMap<String, Any?>()
            return Event(
                id = data["id"] as? String ?: snapshot.id,
                title = data["title"] as? String ?: "",
                location = data["location"] as? String ?: "",
                description = data["description"] as? String ?: "",
                startDateTime = (data["startDateTime"] as? Timestamp).toInstantOrNow(),
                endDateTime = (data["endDateTime"] as? Timestamp).toInstantOrNow(),
                noEndTime = data["noEndTime"] as? Boolean ?: false,
                attendeesAccepted = data["attendeesAccepted"] as? List<String> ?: emptyList(),
                attendeesInvited = data["attendeesInvited"] as? List<String> ?: emptyList(),
                attendeesDeclined = data["attendeesDeclined"] as? List<String> ?: emptyList(),
                host = data["host"] as? String ?: "",
                eventPic = data["eventPic"] as? String ?: "",
                invitedPhoneNumbers = data["invitedPhoneNumbers"] as? List<String> ?: emptyList(),
                acceptedPhoneNumbers = data["acceptedPhoneNumbers"] as? List<String> ?: emptyList(),
                declinedPhoneNumbers = data["declinedPhoneNumbers"] as? List<String> ?: emptyList()
            )
        }
    }
}
