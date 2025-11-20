package com.clique.app.data.repository

import com.clique.app.core.util.PhoneNumberFormatter
import com.clique.app.data.model.Event
import com.clique.app.data.model.EventChatMessage
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
import java.util.Date
import java.util.UUID
import java.time.Instant

class FirebaseCliqueRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
    private val storage: FirebaseStorage = FirebaseStorage.getInstance()
) : CliqueRepository {
    
    // Helper function to convert Instant to Timestamp (API 24+ compatible with desugaring)
    private fun instantToTimestamp(instant: Instant): Timestamp {
        return Timestamp(Date.from(instant))
    }

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
            "startDateTime" to instantToTimestamp(event.startDateTime),
            "endDateTime" to instantToTimestamp(event.endDateTime),
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
        val viewingRequestsRef = firestore.collection("friendRequests").document(viewingUser)
        val viewedRequestsRef = firestore.collection("friendRequests").document(viewedUser)
        val viewingRequestsSentRef = firestore.collection("friendRequestsSent").document(viewingUser)
        val viewedRequestsSentRef = firestore.collection("friendRequestsSent").document(viewedUser)
        
        firestore.runBatch { batch ->
            when (action) {
                FriendshipAction.ADD -> {
                    // Add both users to each other's friends list
                    batch.set(viewingRef, mapOf("friends" to FieldValue.arrayUnion(viewedUser)), SetOptions.merge())
                    batch.set(viewedRef, mapOf("friends" to FieldValue.arrayUnion(viewingUser)), SetOptions.merge())
                    // Remove friend requests from both sides
                    batch.update(viewingRequestsRef, "requests", FieldValue.arrayRemove(viewedUser))
                    batch.update(viewedRequestsRef, "requests", FieldValue.arrayRemove(viewingUser))
                    batch.update(viewingRequestsSentRef, "requests", FieldValue.arrayRemove(viewedUser))
                    batch.update(viewedRequestsSentRef, "requests", FieldValue.arrayRemove(viewingUser))
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

    // Chat methods
    override fun listenToEventChatMessages(eventId: String, onMessagesChanged: (List<EventChatMessage>) -> Unit): ListenerRegistration {
        return chatMessagesCollection(eventId)
            .orderBy("createdAt")
            .limitToLast(200)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    error.printStackTrace()
                    onMessagesChanged(emptyList())
                    return@addSnapshotListener
                }
                val messages = snapshot?.documents?.mapNotNull { doc ->
                    EventChatMessage.fromSnapshot(doc)
                }?.sortedBy { it.createdAt } ?: emptyList()
                onMessagesChanged(messages)
            }
    }

    override suspend fun sendEventChatMessage(eventId: String, senderId: String, senderName: String, text: String) {
        val trimmedText = text.trim()
        if (trimmedText.isEmpty() || eventId.isEmpty()) return

        val messageRef = chatMessagesCollection(eventId).document()
        val timestamp = Timestamp.now()

        val payload = mapOf(
            "id" to messageRef.id,
            "eventId" to eventId,
            "senderId" to senderId,
            "senderEmail" to senderId,
            "senderName" to senderName,
            "text" to trimmedText,
            "createdAt" to timestamp
        )

        messageRef.set(payload).await()
        
        // Update metadata
        updateChatMetadata(eventId, senderId, senderName, timestamp, trimmedText)
    }

    override suspend fun markEventChatAsRead(eventId: String, userId: String) {
        if (eventId.isEmpty() || userId.isEmpty()) return

        val chatDocRef = chatDocument(eventId)
        firestore.runTransaction { transaction ->
            val snapshot = transaction.get(chatDocRef)
            val data = snapshot.data ?: emptyMap<String, Any>()
            
            val unreadCounts = HashMap<String, Any>()
            val readStates = HashMap<String, Any>()
            
            // Copy existing values
            (data["unreadCounts"] as? Map<*, *>)?.forEach { (k, v) ->
                if (k is String) unreadCounts[k] = v ?: 0
            }
            (data["readStates"] as? Map<*, *>)?.forEach { (k, v) ->
                if (k is String) readStates[k] = v ?: Timestamp.now()
            }
            
            unreadCounts[userId] = 0
            readStates[userId] = Timestamp.now()
            
            transaction.update(chatDocRef, mapOf(
                "unreadCounts" to unreadCounts,
                "readStates" to readStates
            ))
            null
        }.await()
    }

    private fun chatDocument(eventId: String): DocumentReference {
        return firestore.collection("eventChats").document(eventId)
    }

    private fun chatMessagesCollection(eventId: String): com.google.firebase.firestore.CollectionReference {
        return chatDocument(eventId).collection("messages")
    }

    private suspend fun updateChatMetadata(eventId: String, senderId: String, senderName: String, timestamp: Timestamp, messageText: String) {
        val chatDocRef = chatDocument(eventId)
        
        firestore.runTransaction { transaction ->
            val snapshot = transaction.get(chatDocRef)
            val data = snapshot.data ?: emptyMap<String, Any>()
            
            val participants = ((data["participants"] as? List<*>)?.mapNotNull { it as? String }?.toSet() ?: emptySet()).toMutableSet()
            participants.add(senderId)
            
            val unreadCounts = HashMap<String, Any>()
            val readStates = HashMap<String, Any>()
            
            // Copy existing values
            (data["unreadCounts"] as? Map<*, *>)?.forEach { (k, v) ->
                if (k is String) unreadCounts[k] = v ?: 0
            }
            (data["readStates"] as? Map<*, *>)?.forEach { (k, v) ->
                if (k is String) readStates[k] = v ?: timestamp
            }
            
            // Update unread counts - sender gets 0, others get +1
            participants.forEach { participant ->
                if (participant == senderId) {
                    unreadCounts[participant] = 0
                } else {
                    val currentCount = (unreadCounts[participant] as? Number)?.toInt() ?: 0
                    unreadCounts[participant] = currentCount + 1
                }
            }
            
            readStates[senderId] = timestamp
            
            transaction.set(chatDocRef, mapOf(
                "eventId" to eventId,
                "lastMessage" to messageText,
                "lastMessageSender" to senderName,
                "lastMessageSenderId" to senderId,
                "lastMessageSenderEmail" to senderId,
                "lastMessageAt" to timestamp,
                "participants" to participants.toList(),
                "unreadCounts" to unreadCounts,
                "readStates" to readStates
            ), SetOptions.merge())
            null
        }.await()
    }
}
