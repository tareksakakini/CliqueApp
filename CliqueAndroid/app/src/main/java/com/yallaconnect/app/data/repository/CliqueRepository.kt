package com.yallaconnect.app.data.repository

import com.yallaconnect.app.data.model.Event
import com.yallaconnect.app.data.model.EventChatMessage
import com.yallaconnect.app.data.model.User
import com.yallaconnect.app.data.repository.model.FriendshipAction
import com.yallaconnect.app.data.repository.model.InviteAction
import com.yallaconnect.app.data.repository.model.UserProfilePayload
import com.google.firebase.firestore.ListenerRegistration

interface CliqueRepository {
    suspend fun fetchUserByAuthUid(authUid: String): User?
    suspend fun fetchUserByUid(uid: String): User?
    suspend fun createUserProfile(payload: UserProfilePayload): User
    suspend fun isUsernameTaken(username: String): Boolean
    suspend fun isUsernameTakenByOtherUser(username: String, excludeUid: String): Boolean
    suspend fun isPhoneRegistered(phoneNumber: String): Boolean
    suspend fun linkPhoneNumberToUser(uid: String, phoneNumber: String): Int
    suspend fun getAllUsers(): List<User>
    suspend fun fetchAllEvents(): List<Event>
    suspend fun getEventById(eventId: String): Event?
    fun listenToEvents(onEventsChanged: (List<Event>) -> Unit): ListenerRegistration
    fun listenToFriends(userId: String, onFriendsChanged: (List<String>) -> Unit): ListenerRegistration
    fun listenToFriendRequests(userId: String, onRequestsChanged: (List<String>) -> Unit): ListenerRegistration
    fun listenToFriendRequestsSent(userId: String, onRequestsChanged: (List<String>) -> Unit): ListenerRegistration
    suspend fun respondToInvite(eventId: String, userId: String, action: InviteAction)
    suspend fun upsertEvent(event: Event, hostId: String, selectedImage: ByteArray?, isNewEvent: Boolean)
    suspend fun deleteEvent(eventId: String)
    suspend fun sendFriendRequest(sender: String, receiver: String)
    suspend fun removeFriendRequest(sender: String, receiver: String)
    suspend fun updateFriendship(viewingUser: String, viewedUser: String, action: FriendshipAction)
    suspend fun updateFullName(uid: String, name: String)
    suspend fun updateUsername(uid: String, username: String)
    suspend fun removeProfilePhoto(uid: String)
    suspend fun uploadProfilePhoto(uid: String, bytes: ByteArray): String
    suspend fun deleteAccount(uid: String, authUid: String)
    
    // Chat methods
    fun listenToEventChatMessages(eventId: String, onMessagesChanged: (List<EventChatMessage>) -> Unit): ListenerRegistration
    suspend fun sendEventChatMessage(eventId: String, senderId: String, senderName: String, text: String)
    suspend fun markEventChatAsRead(eventId: String, userId: String)
}
