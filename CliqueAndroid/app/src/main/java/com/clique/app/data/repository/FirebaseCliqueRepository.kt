package com.clique.app.data.repository

import com.clique.app.core.util.PhoneNumberFormatter
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import com.clique.app.data.repository.model.FriendshipAction
import com.clique.app.data.repository.model.InviteAction
import com.clique.app.data.repository.model.UserProfilePayload
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import com.google.firebase.storage.FirebaseStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.util.UUID

class FirebaseCliqueRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
    private val storage: FirebaseStorage = FirebaseStorage.getInstance()
) : CliqueRepository {

    private val usersCollection = firestore.collection("users")
    private val eventsCollection = firestore.collection("events")

    override suspend fun fetchUserByAuthUid(authUid: String): User? {
        if (authUid.isBlank()) return null
        val snapshot = usersCollection
            .whereEqualTo("authUID", authUid)
            .limit(1)
            .get()
            .await()
        return snapshot.documents.firstOrNull()?.let(User::fromSnapshot)
    }

    override suspend fun fetchUserByUid(uid: String): User? {
        if (uid.isBlank()) return null
        val document = usersCollection.document(uid).get().await()
        return if (document.exists()) User.fromSnapshot(document) else null
    }

    override suspend fun createUserProfile(payload: UserProfilePayload): User {
        val normalizedPhone = PhoneNumberFormatter.e164(payload.phoneNumber)
            .ifBlank { PhoneNumberFormatter.canonical(payload.phoneNumber) }
        val userMap = mapOf(
            "uid" to payload.uid,
            "authUID" to payload.authUid,
            "fullname" to payload.fullName,
            "username" to payload.username,
            "profilePic" to "userDefault",
            "gender" to payload.gender,
            "createdAt" to Timestamp.now(),
            "phoneNumber" to normalizedPhone
        )
        usersCollection.document(payload.uid).set(userMap).await()
        return usersCollection.document(payload.uid).get().await().let(User::fromSnapshot)
    }

    override suspend fun isUsernameTaken(username: String): Boolean {
        if (username.isBlank()) return false
        val snapshot = usersCollection.whereEqualTo("username", username).get().await()
        return snapshot.documents.any { (it.get("username") as? String)?.isNotBlank() == true }
    }

    override suspend fun isPhoneRegistered(phoneNumber: String): Boolean {
        if (phoneNumber.isBlank()) return false
        val canonical = PhoneNumberFormatter.canonical(phoneNumber)
        val e164 = PhoneNumberFormatter.e164(phoneNumber)
        val digits = PhoneNumberFormatter.digitsOnly(phoneNumber)
        val candidates = listOf(canonical, e164, digits, phoneNumber.trim())
            .filter { it.isNotBlank() }
            .distinct()
        if (candidates.isEmpty()) return false
        val matches = mutableSetOf<String>()
        candidates.forEach { candidate ->
            val snapshot = usersCollection.whereEqualTo("phoneNumber", candidate).get().await()
            snapshot.documents.forEach { doc ->
                val stored = doc.getString("phoneNumber") ?: return@forEach
                if (PhoneNumberFormatter.numbersMatch(stored, phoneNumber)) {
                    matches.add(doc.id)
                }
            }
        }
        return matches.isNotEmpty()
    }

    override suspend fun linkPhoneNumberToUser(uid: String, phoneNumber: String): Int {
        if (uid.isBlank() || phoneNumber.isBlank()) return 0
        val normalized = PhoneNumberFormatter.e164(phoneNumber)
            .ifBlank { PhoneNumberFormatter.canonical(phoneNumber) }
        usersCollection.document(uid)
            .update("phoneNumber", normalized)
            .await()

        val events = fetchAllEvents()
        var updatedCount = 0
        events.forEach { event ->
            if (event.id.isBlank()) return@forEach
            var eventUpdated = false
            val updatedInvitedPhones = event.invitedPhoneNumbers.toMutableList()
            val updatedAcceptedPhones = event.acceptedPhoneNumbers.toMutableList()
            val updatedDeclinedPhones = event.declinedPhoneNumbers.toMutableList()
            val invited = event.attendeesInvited.toMutableList()
            val accepted = event.attendeesAccepted.toMutableList()
            val declined = event.attendeesDeclined.toMutableList()

            fun moveFromPhones(phones: MutableList<String>, destination: MutableList<String>) {
                val iterator = phones.iterator()
                while (iterator.hasNext()) {
                    val phone = iterator.next()
                    if (PhoneNumberFormatter.numbersMatch(phone, phoneNumber)) {
                        iterator.remove()
                        if (!destination.contains(uid)) destination.add(uid)
                        eventUpdated = true
                    }
                }
            }

            moveFromPhones(updatedInvitedPhones, invited)
            moveFromPhones(updatedAcceptedPhones, accepted)
            moveFromPhones(updatedDeclinedPhones, declined)

            if (eventUpdated) {
                val payload = mapOf(
                    "attendeesInvited" to invited,
                    "attendeesAccepted" to accepted,
                    "attendeesDeclined" to declined,
                    "invitedPhoneNumbers" to updatedInvitedPhones,
                    "acceptedPhoneNumbers" to updatedAcceptedPhones,
                    "declinedPhoneNumbers" to updatedDeclinedPhones
                )
                eventsCollection.document(event.id).update(payload).await()
                updatedCount++
            }
        }
        return updatedCount
    }

    override suspend fun getAllUsers(): List<User> {
        val snapshot = usersCollection.get().await()
        return snapshot.documents.map(User::fromSnapshot)
    }

    override suspend fun fetchAllEvents(): List<Event> {
        val snapshot = eventsCollection.get().await()
        return snapshot.documents.map(Event::fromSnapshot)
    }

    override suspend fun getEventById(eventId: String): Event? {
        if (eventId.isBlank()) return null
        val document = eventsCollection.document(eventId).get().await()
        return if (document.exists()) Event.fromSnapshot(document) else null
    }

    override fun listenToEvents(onEventsChanged: (List<Event>) -> Unit): ListenerRegistration {
        return eventsCollection.addSnapshotListener { snapshot, error ->
            if (error != null) {
                error.printStackTrace()
                return@addSnapshotListener
            }
            val events = snapshot?.documents?.map(Event::fromSnapshot).orEmpty()
                .sortedBy { it.startDateTime }
            onEventsChanged(events)
        }
    }

    override fun listenToFriends(userId: String, onFriendsChanged: (List<String>) -> Unit): ListenerRegistration {
        return firestore.collection("friendships")
            .document(userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    error.printStackTrace()
                    return@addSnapshotListener
                }
                val friends = snapshot?.get("friends") as? List<String> ?: emptyList()
                onFriendsChanged(friends)
            }
    }

    override fun listenToFriendRequests(userId: String, onRequestsChanged: (List<String>) -> Unit): ListenerRegistration {
        return firestore.collection("friendRequests")
            .document(userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    error.printStackTrace()
                    return@addSnapshotListener
                }
                val requests = snapshot?.get("requests") as? List<String> ?: emptyList()
                onRequestsChanged(requests)
            }
    }

    override fun listenToFriendRequestsSent(userId: String, onRequestsChanged: (List<String>) -> Unit): ListenerRegistration {
        return firestore.collection("friendRequestsSent")
            .document(userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    error.printStackTrace()
                    return@addSnapshotListener
                }
                val requests = snapshot?.get("requests") as? List<String> ?: emptyList()
                onRequestsChanged(requests)
            }
    }

    override suspend fun respondToInvite(eventId: String, userId: String, action: InviteAction) {
        val eventRef = eventsCollection.document(eventId)
        firestore.runTransaction { transaction ->
            val snapshot = transaction.get(eventRef)
            val invited = (snapshot.get("attendeesInvited") as? List<String>)?.toMutableList() ?: mutableListOf()
            val accepted = (snapshot.get("attendeesAccepted") as? List<String>)?.toMutableList() ?: mutableListOf()
            val declined = (snapshot.get("attendeesDeclined") as? List<String>)?.toMutableList() ?: mutableListOf()
            var host = snapshot.getString("host") ?: ""

            fun MutableList<String>.removeUser(uidValue: String) {
                removeAll { it == uidValue }
            }

            when (action) {
                InviteAction.ACCEPT -> {
                    invited.removeUser(userId)
                    if (!accepted.contains(userId)) accepted.add(userId)
                    declined.removeUser(userId)
                }
                InviteAction.DECLINE -> {
                    invited.removeUser(userId)
                    if (!declined.contains(userId)) declined.add(userId)
                    accepted.removeUser(userId)
                }
                InviteAction.ACCEPT_DECLINED -> {
                    declined.removeUser(userId)
                    if (!accepted.contains(userId)) accepted.add(userId)
                }
                InviteAction.LEAVE -> {
                    if (host == userId) {
                        host = ""
                    }
                    accepted.removeUser(userId)
                    if (!declined.contains(userId)) declined.add(userId)
                }
            }

            transaction.update(eventRef, mapOf(
                "attendeesInvited" to invited,
                "attendeesAccepted" to accepted,
                "attendeesDeclined" to declined,
                "host" to host
            ))
        }.await()
    }

    override suspend fun upsertEvent(event: Event, hostId: String, selectedImage: ByteArray?, isNewEvent: Boolean) {
        val eventId = if (event.id.isBlank()) UUID.randomUUID().toString() else event.id
        val payload = mapOf(
            "id" to eventId,
            "title" to event.title,
            "location" to event.location,
            "description" to event.description,
            "startDateTime" to Timestamp(event.startDateTime.epochSecond, event.startDateTime.nano),
            "endDateTime" to Timestamp(event.endDateTime.epochSecond, event.endDateTime.nano),
            "noEndTime" to event.noEndTime,
            "attendeesAccepted" to event.attendeesAccepted,
            "attendeesInvited" to event.attendeesInvited,
            "attendeesDeclined" to event.attendeesDeclined,
            "host" to hostId,
            "invitedPhoneNumbers" to event.invitedPhoneNumbers,
            "acceptedPhoneNumbers" to event.acceptedPhoneNumbers,
            "declinedPhoneNumbers" to event.declinedPhoneNumbers
        )
        val ref = eventsCollection.document(eventId)
        ref.set(payload).await()
        if (selectedImage != null) {
            uploadEventImage(eventId, selectedImage, ref)
        }
    }

    override suspend fun deleteEvent(eventId: String) {
        eventsCollection.document(eventId).delete().await()
    }

    override suspend fun sendFriendRequest(sender: String, receiver: String) {
        val receiverRef = firestore.collection("friendRequests").document(receiver)
        val senderRef = firestore.collection("friendRequestsSent").document(sender)
        firestore.runBatch { batch ->
            batch.set(receiverRef, mapOf("requests" to FieldValue.arrayUnion(sender)), SetOptions.merge())
            batch.set(senderRef, mapOf("requests" to FieldValue.arrayUnion(receiver)), SetOptions.merge())
        }.await()
    }

    override suspend fun removeFriendRequest(sender: String, receiver: String) {
        val receiverRef = firestore.collection("friendRequests").document(receiver)
        val senderRef = firestore.collection("friendRequestsSent").document(sender)
        firestore.runBatch { batch ->
            batch.update(receiverRef, "requests", FieldValue.arrayRemove(sender))
            batch.update(senderRef, "requests", FieldValue.arrayRemove(receiver))
        }.await()
    }

    override suspend fun updateFriendship(viewingUser: String, viewedUser: String, action: FriendshipAction) {
        val viewingRef = firestore.collection("friendships").document(viewingUser)
        val viewedRef = firestore.collection("friendships").document(viewedUser)
        firestore.runBatch { batch ->
            when (action) {
                FriendshipAction.ADD -> {
                    batch.set(viewingRef, mapOf("friends" to FieldValue.arrayUnion(viewedUser)), SetOptions.merge())
                    batch.set(viewedRef, mapOf("friends" to FieldValue.arrayUnion(viewingUser)), SetOptions.merge())
                }
                FriendshipAction.REMOVE -> {
                    batch.update(viewingRef, "friends", FieldValue.arrayRemove(viewedUser))
                    batch.update(viewedRef, "friends", FieldValue.arrayRemove(viewingUser))
                }
            }
        }.await()
    }

    override suspend fun updateFullName(uid: String, name: String) {
        usersCollection.document(uid).update("fullname", name).await()
    }

    override suspend fun updateUsername(uid: String, username: String) {
        usersCollection.document(uid).update("username", username).await()
    }

    override suspend fun removeProfilePhoto(uid: String) {
        usersCollection.document(uid).update("profilePic", "userDefault").await()
    }

    override suspend fun uploadProfilePhoto(uid: String, bytes: ByteArray): String {
        val ref = storage.reference.child("profile_pictures/$uid.jpg")
        ref.putBytes(bytes).await()
        val url = ref.downloadUrl.await().toString()
        usersCollection.document(uid).update("profilePic", url).await()
        return url
    }

    private suspend fun uploadEventImage(eventId: String, bytes: ByteArray, reference: DocumentReference) {
        withContext(Dispatchers.IO) {
            val ref = storage.reference.child("event_images/$eventId.jpg")
            ref.putBytes(bytes).await()
            val url = ref.downloadUrl.await().toString()
            reference.update("eventPic", url).await()
        }
    }
}
