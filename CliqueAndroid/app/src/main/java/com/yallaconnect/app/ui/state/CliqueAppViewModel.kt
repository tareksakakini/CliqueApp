package com.yallaconnect.app.ui.state

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yallaconnect.app.core.auth.PhoneAuthManager
import com.yallaconnect.app.core.network.NetworkMonitor
import com.yallaconnect.app.core.notifications.NotificationRouter
import com.yallaconnect.app.core.notifications.NotificationRouteBuilder
import com.yallaconnect.app.core.notifications.OneSignalManager
import com.yallaconnect.app.core.util.PhoneNumberFormatter
import com.yallaconnect.app.data.model.Country
import com.yallaconnect.app.data.model.Event
import com.yallaconnect.app.data.model.EventChatMessage
import com.yallaconnect.app.data.model.User
import com.yallaconnect.app.data.repository.CliqueRepository
import com.yallaconnect.app.data.repository.model.FriendshipAction
import com.yallaconnect.app.data.repository.model.InviteAction
import com.yallaconnect.app.data.repository.model.UserProfilePayload
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthProvider
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.UUID

class CliqueAppViewModel(
    private val repository: CliqueRepository,
    private val phoneAuthManager: PhoneAuthManager,
    private val networkMonitor: NetworkMonitor,
    private val notificationRouter: NotificationRouter,
    private val oneSignalManager: OneSignalManager,
    private val firebaseAuth: FirebaseAuth
) : ViewModel() {

    private val _sessionState = MutableStateFlow(SessionState())
    val sessionState: StateFlow<SessionState> = _sessionState.asStateFlow()

    private val _verificationState = MutableStateFlow(VerificationUiState())
    val verificationState: StateFlow<VerificationUiState> = _verificationState.asStateFlow()

    private val _pendingAccount = MutableStateFlow<PendingAccount?>(null)
    val pendingAccount: StateFlow<PendingAccount?> = _pendingAccount.asStateFlow()

    private val _networkAvailable = MutableStateFlow(true)
    val networkAvailable: StateFlow<Boolean> = _networkAvailable.asStateFlow()

    private val _users = MutableStateFlow<List<User>>(emptyList())
    val users: StateFlow<List<User>> = _users.asStateFlow()

    private var eventsListener: ListenerRegistration? = null
    private var friendsListener: ListenerRegistration? = null
    private var friendRequestsListener: ListenerRegistration? = null
    private var friendRequestsSentListener: ListenerRegistration? = null
    private var chatMessageListeners = mutableMapOf<String, ListenerRegistration>()

    private var routerJob: Job? = null
    private var countdownJob: Job? = null
    private var resendToken: PhoneAuthProvider.ForceResendingToken? = null

    val pendingRoute: StateFlow<NotificationRouter.Destination?> = notificationRouter.pendingRoute

    init {
        observeNetwork()
        observeRouting()
        restoreExistingSession()
    }

    private fun observeNetwork() {
        viewModelScope.launch {
            networkMonitor.isConnected.collect { connected ->
                _networkAvailable.value = connected
            }
        }
    }

    private fun observeRouting() {
        routerJob?.cancel()
        routerJob = viewModelScope.launch {
            notificationRouter.pendingRoute.collect { }
        }
    }

    fun consumeRoute() {
        notificationRouter.consumeRoute()
    }

    private fun restoreExistingSession() {
        val existingAuth = firebaseAuth.currentUser ?: run {
            _sessionState.update { it.copy(isLoading = false) }
            return
        }
        viewModelScope.launch {
            _sessionState.update { it.copy(isLoading = true) }
            val user = repository.fetchUserByAuthUid(existingAuth.uid)
            if (user != null) {
                completeSignIn(user)
            } else {
                _sessionState.update { SessionState(isLoading = false) }
            }
        }
    }

    fun sendVerificationCode(activity: Activity, rawPhone: String, country: Country, mode: AuthMode) {
        viewModelScope.launch {
            val digits = rawPhone.filter { it.isDigit() }
            val formatted = PhoneNumberFormatter.e164(country.dialCode, digits)
            if (formatted.isBlank()) {
                _verificationState.update { it.copy(errorMessage = "Please enter a valid phone number") }
                return@launch
            }
            _verificationState.update {
                it.copy(
                    isSendingCode = true,
                    errorMessage = null,
                    selectedCountry = country,
                    phoneNumber = formatted,
                    mode = mode
                )
            }
            try {
                when (mode) {
                    AuthMode.SIGN_IN -> {
                        val registered = repository.isPhoneRegistered(formatted)
                        if (!registered) {
                            _verificationState.update {
                                it.copy(isSendingCode = false, errorMessage = "Phone number not registered")
                            }
                            return@launch
                        }
                    }
                    AuthMode.SIGN_UP -> {
                        val registered = repository.isPhoneRegistered(formatted)
                        if (registered) {
                            _verificationState.update {
                                it.copy(isSendingCode = false, errorMessage = "Phone number already registered")
                            }
                            return@launch
                        }
                    }
                }
                val result = phoneAuthManager.sendVerificationCode(activity, formatted)
                resendToken = result.resendToken
                startResendCountdown()
                _verificationState.update {
                    it.copy(
                        verificationId = result.verificationId,
                        isSendingCode = false,
                        errorMessage = null,
                        phoneNumber = formatted,
                        mode = mode
                    )
                }
            } catch (error: Exception) {
                _verificationState.update {
                    it.copy(isSendingCode = false, errorMessage = error.localizedMessage ?: "Failed to send code")
                }
            }
        }
    }

    fun resetVerificationState() {
        countdownJob?.cancel()
        resendToken = null
        _verificationState.value = VerificationUiState()
    }

    fun resendVerificationCode(activity: Activity) {
        val token = resendToken ?: return
        val phoneNumber = _verificationState.value.phoneNumber
        if (phoneNumber.isBlank()) return

        viewModelScope.launch {
            _verificationState.update { it.copy(isSendingCode = true, errorMessage = null) }
            try {
                val result = phoneAuthManager.resendVerificationCode(activity, phoneNumber, token)
                resendToken = result.resendToken
                startResendCountdown()
                _verificationState.update {
                    it.copy(
                        verificationId = result.verificationId,
                        isSendingCode = false,
                        errorMessage = null
                    )
                }
            } catch (error: Exception) {
                _verificationState.update {
                    it.copy(isSendingCode = false, errorMessage = error.localizedMessage ?: "Failed to resend code")
                }
            }
        }
    }

    private fun startResendCountdown() {
        countdownJob?.cancel()
        _verificationState.update { it.copy(resendCountdown = 60) }
        countdownJob = viewModelScope.launch {
            for (i in 60 downTo 0) {
                delay(1000)
                _verificationState.update { it.copy(resendCountdown = i) }
            }
        }
    }

    fun verifyCode(verificationId: String, smsCode: String, mode: AuthMode) {
        viewModelScope.launch {
            _verificationState.update { it.copy(isVerifyingCode = true, errorMessage = null) }
            try {
                val firebaseUser = phoneAuthManager.verifyCode(verificationId, smsCode)
                when (mode) {
                    AuthMode.SIGN_IN -> {
                        val user = repository.fetchUserByAuthUid(firebaseUser.uid)
                        if (user != null) {
                            completeSignIn(user)
                        } else {
                            _verificationState.update {
                                it.copy(isVerifyingCode = false, errorMessage = "Account not found")
                            }
                        }
                    }
                    AuthMode.SIGN_UP -> {
                        _pendingAccount.value = PendingAccount(
                            authUid = firebaseUser.uid,
                            phoneNumber = _verificationState.value.phoneNumber
                        )
                        _verificationState.update { it.copy(isVerifyingCode = false) }
                    }
                }
            } catch (error: Exception) {
                _verificationState.update {
                    it.copy(isVerifyingCode = false, errorMessage = error.localizedMessage ?: "Verification failed")
                }
            }
        }
    }

    fun completeAccountCreation(fullName: String, username: String, gender: String, onResult: (AccountCreationResult) -> Unit) {
        val pending = _pendingAccount.value ?: run {
            onResult(AccountCreationResult.Error("Verification required"))
            return
        }
        viewModelScope.launch {
            if (username.isBlank() || fullName.isBlank()) {
                onResult(AccountCreationResult.Error("All fields are required"))
                return@launch
            }
            if (repository.isUsernameTaken(username)) {
                onResult(AccountCreationResult.Error("Username already taken"))
                return@launch
            }
            try {
                val payload = UserProfilePayload(
                    uid = UUID.randomUUID().toString(),
                    authUid = pending.authUid,
                    phoneNumber = pending.phoneNumber,
                    fullName = fullName,
                    username = username,
                    gender = gender
                )
                val user = repository.createUserProfile(payload)
                completeSignIn(user)
                _pendingAccount.value = null
                onResult(AccountCreationResult.Success(user))
            } catch (error: Exception) {
                onResult(AccountCreationResult.Error(error.localizedMessage ?: "Account creation failed"))
            }
        }
    }

    private fun completeSignIn(user: User) {
        viewModelScope.launch {
            _sessionState.update { it.copy(user = user, isLoading = false, errorMessage = null) }
            startRealtimeListeners(user.uid)
            loadUsers()
            runCatching { repository.linkPhoneNumberToUser(user.uid, user.phoneNumber) }
            
            // Log OneSignal status before login
            val statusBefore = oneSignalManager.getStatus()
            android.util.Log.d("CliqueAppViewModel", "🔐 Logging user into OneSignal: ${user.uid}")
            android.util.Log.d("CliqueAppViewModel", "   OneSignal status before login: $statusBefore")
            
            oneSignalManager.login(user.uid)
            
            // Verify login after a short delay
            kotlinx.coroutines.delay(500)
            val statusAfter = oneSignalManager.getStatus()
            android.util.Log.d("CliqueAppViewModel", "   OneSignal status after login: $statusAfter")
            
            if (oneSignalManager.isConfiguredFor(user.uid)) {
                android.util.Log.d("CliqueAppViewModel", "✅ User successfully logged into OneSignal")
            } else {
                android.util.Log.w("CliqueAppViewModel", "⚠️ User may not be properly logged into OneSignal. External ID mismatch.")
            }
        }
    }

    private fun startRealtimeListeners(userId: String) {
        eventsListener?.remove()
        friendsListener?.remove()
        friendRequestsListener?.remove()
        friendRequestsSentListener?.remove()

        eventsListener = repository.listenToEvents { events ->
            _sessionState.update { it.copy(events = events.sortedBy { event -> event.startDateTime }) }
        }
        friendsListener = repository.listenToFriends(userId) { friends ->
            _sessionState.update { it.copy(friendships = friends) }
        }
        friendRequestsListener = repository.listenToFriendRequests(userId) { requests ->
            _sessionState.update { it.copy(friendRequests = requests) }
        }
        friendRequestsSentListener = repository.listenToFriendRequestsSent(userId) { requests ->
            _sessionState.update { it.copy(friendRequestsSent = requests) }
        }
    }

    private fun loadUsers() {
        viewModelScope.launch {
            _users.value = repository.getAllUsers()
        }
    }

    fun refreshEvents() {
        viewModelScope.launch {
            try {
                val events = repository.fetchAllEvents()
                _sessionState.update { it.copy(events = events.sortedBy { event -> event.startDateTime }) }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }
    
    fun refreshAll() {
        viewModelScope.launch {
            try {
                // Refresh events
                val events = repository.fetchAllEvents()
                _sessionState.update { it.copy(events = events.sortedBy { event -> event.startDateTime }) }
                
                // Refresh users
                _users.value = repository.getAllUsers()
                
                // Friendship data is automatically updated via listeners
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun respondToInvite(eventId: String, action: InviteAction) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                val event = repository.getEventById(eventId)
                repository.respondToInvite(eventId, user.uid, action)
                
                // Send notification to host
                if (event != null && event.host.isNotBlank() && event.host != user.uid && event.id.isNotBlank()) {
                    val host = _users.value.find { it.uid == event.host }
                    if (host != null) {
                        val notificationText = when (action) {
                            InviteAction.ACCEPT -> "${user.fullName} is coming to your event!"
                            InviteAction.DECLINE -> "${user.fullName} cannot make it to your event."
                            InviteAction.LEAVE -> "${user.fullName} cannot make it anymore to your event."
                            InviteAction.ACCEPT_DECLINED -> "${user.fullName} has accepted your event invitation!"
                        }
                        val route = NotificationRouteBuilder.eventDetail(
                            eventId = event.id,
                            inviteView = false,
                            preferredTab = NotificationRouter.NotificationTab.MY_EVENTS
                        )
                        oneSignalManager.sendPushNotification(
                            message = notificationText,
                            receiverUid = host.uid,
                            route = route
                        )
                    }
                }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun saveEvent(event: Event, isNew: Boolean, imageBytes: ByteArray?) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                // Generate event ID for new events if not already set
                val finalEventId = if (isNew && event.id.isBlank()) {
                    UUID.randomUUID().toString()
                } else {
                    event.id
                }
                
                // Create event with final ID
                val eventWithId = event.copy(id = finalEventId)
                
                // Get old event if updating
                val oldEvent = if (!isNew && finalEventId.isNotBlank()) {
                    repository.getEventById(finalEventId)
                } else {
                    null
                }
                
                repository.upsertEvent(eventWithId, hostId = user.uid, selectedImage = imageBytes, isNewEvent = isNew)
                
                if (isNew) {
                    // Send invitations to new invitees
                    val newInvitees = eventWithId.attendeesInvited
                    
                    if (newInvitees.isNotEmpty() && finalEventId.isNotBlank()) {
                        val invitationText = "${user.fullName} just invited you to an event!"
                        newInvitees.forEach { inviteeId ->
                            val invitee = _users.value.find { it.uid == inviteeId }
                            if (invitee != null) {
                                val route = NotificationRouteBuilder.eventDetail(
                                    eventId = finalEventId,
                                    inviteView = true,
                                    preferredTab = NotificationRouter.NotificationTab.INVITES
                                )
                                oneSignalManager.sendPushNotification(
                                    message = invitationText,
                                    receiverUid = inviteeId,
                                    route = route
                                )
                            }
                        }
                    }
                } else if (oldEvent != null) {
                    // Send update notifications for existing invitees
                    sendEventUpdateNotifications(user, oldEvent, eventWithId)
                }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }
    
    private suspend fun sendEventUpdateNotifications(user: User, oldEvent: Event, newEvent: Event) {
        // Collect all changes
        val changes = mutableListOf<String>()
        
        if (oldEvent.title != newEvent.title) {
            changes.add("title")
        }
        if (oldEvent.location != newEvent.location) {
            changes.add("location")
        }
        if (oldEvent.description != newEvent.description) {
            changes.add("description")
        }
        if (oldEvent.startDateTime != newEvent.startDateTime) {
            changes.add("start time")
        }
        if (oldEvent.endDateTime != newEvent.endDateTime) {
            changes.add("end time")
        }
        
        // If no relevant changes, don't send notifications
        if (changes.isEmpty()) {
            return
        }
        
        // Create notification message
        val notificationText = createEventUpdateNotificationText(
            hostName = user.fullName,
            oldEventTitle = oldEvent.title,
            newEventTitle = newEvent.title,
            changes = changes
        )
        
        // Get all invitees (accepted, invited, and declined)
        val allInvitees = (oldEvent.attendeesAccepted + oldEvent.attendeesInvited + oldEvent.attendeesDeclined).toSet()
        
        // Send notifications to all invitees except the host
        allInvitees.forEach { inviteeId ->
            if (inviteeId != user.uid && newEvent.id.isNotBlank()) {
                val invitee = _users.value.find { it.uid == inviteeId }
                if (invitee != null) {
                    val inviteView = newEvent.attendeesInvited.contains(inviteeId) || 
                                     newEvent.attendeesDeclined.contains(inviteeId)
                    val preferredTab = if (inviteView) {
                        NotificationRouter.NotificationTab.INVITES
                    } else {
                        NotificationRouter.NotificationTab.MY_EVENTS
                    }
                    val route = NotificationRouteBuilder.eventDetail(
                        eventId = newEvent.id,
                        inviteView = inviteView,
                        preferredTab = preferredTab
                    )
                    oneSignalManager.sendPushNotification(
                        message = notificationText,
                        receiverUid = inviteeId,
                        route = route
                    )
                }
            }
        }
    }
    
    private fun createEventUpdateNotificationText(
        hostName: String,
        oldEventTitle: String,
        newEventTitle: String,
        changes: List<String>
    ): String {
        val titleChanged = changes.contains("title")
        val displayTitle = oldEventTitle // Always use old title so users know which event
        
        return when {
            changes.size == 1 -> {
                if (titleChanged) {
                    "$hostName changed the title of $oldEventTitle (now $newEventTitle)"
                } else {
                    "$hostName changed the ${changes[0]} of $displayTitle"
                }
            }
            changes.size == 2 -> {
                if (titleChanged) {
                    val otherChange = changes.firstOrNull { it != "title" } ?: ""
                    "$hostName changed the title and $otherChange of $oldEventTitle (now $newEventTitle)"
                } else {
                    "$hostName changed the ${changes[0]} and ${changes[1]} of $displayTitle"
                }
            }
            else -> {
                // For 3+ changes
                if (titleChanged) {
                    "$hostName changed the title and other details of $oldEventTitle (now $newEventTitle)"
                } else {
                    "$hostName changed multiple details of $displayTitle"
                }
            }
        }
    }

    fun deleteEvent(eventId: String) {
        viewModelScope.launch {
            try {
                repository.deleteEvent(eventId)
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    suspend fun refreshEvent(eventId: String): Event? {
        return try {
            repository.getEventById(eventId)
        } catch (error: Exception) {
            _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            null
        }
    }

    fun listenToEventChatMessages(eventId: String, onMessagesChanged: (List<EventChatMessage>) -> Unit) {
        chatMessageListeners[eventId]?.remove()
        chatMessageListeners[eventId] = repository.listenToEventChatMessages(eventId, onMessagesChanged)
    }

    fun stopListeningToEventChatMessages(eventId: String) {
        chatMessageListeners[eventId]?.remove()
        chatMessageListeners.remove(eventId)
    }

    fun sendEventChatMessage(eventId: String, text: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                val event = repository.getEventById(eventId)
                repository.sendEventChatMessage(eventId, user.uid, user.fullName, text)
                
                // Send notifications to all participants except sender
                if (event != null && event.id.isNotBlank()) {
                    val recipients = event.chatParticipantUserIds.filter { it != user.uid }
                    if (recipients.isNotEmpty()) {
                        val snippet = if (text.length > 120) text.take(117) + "..." else text
                        
                        recipients.forEach { recipientId ->
                            val recipient = _users.value.find { it.uid == recipientId }
                            if (recipient != null) {
                                val inviteView = event.isInviteContextFor(recipientId, recipient.phoneNumber)
                                val preferredTab = if (inviteView) {
                                    NotificationRouter.NotificationTab.INVITES
                                } else {
                                    NotificationRouter.NotificationTab.MY_EVENTS
                                }
                                val route = NotificationRouteBuilder.eventDetail(
                                    eventId = event.id,
                                    inviteView = inviteView,
                                    preferredTab = preferredTab,
                                    openChat = true
                                )
                                oneSignalManager.sendPushNotification(
                                    message = "${user.fullName}: $snippet",
                                    receiverUid = recipientId,
                                    route = route,
                                    title = event.title
                                )
                            }
                        }
                    }
                }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun markEventChatAsRead(eventId: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.markEventChatAsRead(eventId, user.uid)
            } catch (error: Exception) {
                // Silently fail for read marking
            }
        }
    }

    fun sendFriendRequest(receiver: String) {
        val user = _sessionState.value.user ?: return
        if (receiver == user.uid) return
        viewModelScope.launch {
            try {
                android.util.Log.d("CliqueAppViewModel", "📤 Sending friend request from ${user.uid} to $receiver")
                repository.sendFriendRequest(user.uid, receiver)
                android.util.Log.d("CliqueAppViewModel", "✅ Friend request saved to database")
                
                // Send notification to receiver
                val route = NotificationRouteBuilder.friends(NotificationRouter.FriendSectionShortcut.REQUESTS)
                android.util.Log.d("CliqueAppViewModel", "📤 Sending notification with route: $route")
                oneSignalManager.sendPushNotification(
                    message = "${user.fullName} just sent you a friend request!",
                    receiverUid = receiver,
                    route = route
                )
                android.util.Log.d("CliqueAppViewModel", "✅ Notification send attempt completed")
            } catch (error: Exception) {
                android.util.Log.e("CliqueAppViewModel", "❌ Error sending friend request: ${error.message}", error)
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun removeFriendRequest(otherUserId: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                // When declining: otherUserId is the sender, user.uid is the receiver
                // When unsending: otherUserId is the receiver, user.uid is the sender
                // The repository expects: removeFriendRequest(sender, receiver)
                // So we need to determine which is which based on context
                // Since friendRequests contains otherUserId, it means otherUserId sent to current user
                // Since friendRequestsSent contains otherUserId, it means current user sent to otherUserId
                val friendRequests = _sessionState.value.friendRequests
                val friendRequestsSent = _sessionState.value.friendRequestsSent
                
                if (friendRequests.contains(otherUserId)) {
                    // Current user received request from otherUserId, so otherUserId is sender
                    repository.removeFriendRequest(otherUserId, user.uid)
                } else if (friendRequestsSent.contains(otherUserId)) {
                    // Current user sent request to otherUserId, so user.uid is sender
                    repository.removeFriendRequest(user.uid, otherUserId)
                }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun updateFriendship(viewedUser: String, action: FriendshipAction) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.updateFriendship(user.uid, viewedUser, action)
                
                // Send notification when accepting friendship
                if (action == FriendshipAction.ADD) {
                    val route = NotificationRouteBuilder.friends(NotificationRouter.FriendSectionShortcut.FRIENDS)
                    oneSignalManager.sendPushNotification(
                        message = "${user.fullName} just accepted your friend request!",
                        receiverUid = viewedUser,
                        route = route
                    )
                }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun updateFullName(fullName: String, onResult: (UpdateResult) -> Unit) {
        val user = _sessionState.value.user ?: run {
            onResult(UpdateResult.Error("User not found"))
            return
        }
        if (fullName.isBlank()) {
            onResult(UpdateResult.Error("Full name cannot be empty"))
            return
        }
        viewModelScope.launch {
            try {
                repository.updateFullName(user.uid, fullName)
                _sessionState.update { it.copy(user = user.copy(fullName = fullName)) }
                onResult(UpdateResult.Success)
            } catch (error: Exception) {
                val errorMsg = error.localizedMessage ?: "Failed to update full name"
                _sessionState.update { it.copy(errorMessage = errorMsg) }
                onResult(UpdateResult.Error(errorMsg))
            }
        }
    }

    fun checkUsernameAvailability(username: String, excludeUid: String? = null, onResult: (Boolean) -> Unit) {
        val normalizedUsername = username.lowercase().trim()
        if (normalizedUsername.isBlank() || normalizedUsername.length < 3) {
            onResult(false)
            return
        }
        viewModelScope.launch {
            try {
                val isTaken = if (excludeUid != null) {
                    repository.isUsernameTakenByOtherUser(normalizedUsername, excludeUid)
                } else {
                    repository.isUsernameTaken(normalizedUsername)
                }
                onResult(!isTaken)
            } catch (error: Exception) {
                // On error, assume unavailable to be safe
                onResult(false)
            }
        }
    }

    fun updateUsername(username: String, onResult: (UpdateResult) -> Unit) {
        val user = _sessionState.value.user ?: run {
            onResult(UpdateResult.Error("User not found"))
            return
        }
        val normalizedUsername = username.lowercase().trim()
        if (normalizedUsername.isBlank()) {
            onResult(UpdateResult.Error("Username cannot be empty"))
            return
        }
        // If username hasn't changed, no need to update
        if (normalizedUsername == user.username) {
            onResult(UpdateResult.Success)
            return
        }
        viewModelScope.launch {
            try {
                // Check if username is already taken by another user
                if (repository.isUsernameTakenByOtherUser(normalizedUsername, user.uid)) {
                    onResult(UpdateResult.Error("Username already taken"))
                    return@launch
                }
                repository.updateUsername(user.uid, normalizedUsername)
                _sessionState.update { it.copy(user = user.copy(username = normalizedUsername)) }
                onResult(UpdateResult.Success)
            } catch (error: Exception) {
                val errorMsg = error.localizedMessage ?: "Failed to update username"
                _sessionState.update { it.copy(errorMessage = errorMsg) }
                onResult(UpdateResult.Error(errorMsg))
            }
        }
    }

    fun deleteAccount(onResult: (DeleteAccountResult) -> Unit) {
        val user = _sessionState.value.user ?: run {
            onResult(DeleteAccountResult.Error("User not found"))
            return
        }
        viewModelScope.launch {
            try {
                // Delete from Firestore
                repository.deleteAccount(user.uid, user.authUid)
                
                // Delete Firebase Auth user
                val currentUser = firebaseAuth.currentUser
                if (currentUser != null && currentUser.uid == user.authUid) {
                    currentUser.delete().await()
                }
                
                // Clean up listeners
                eventsListener?.remove()
                friendsListener?.remove()
                friendRequestsListener?.remove()
                friendRequestsSentListener?.remove()
                
                // Sign out and clear state
                oneSignalManager.logout()
                _sessionState.value = SessionState(isLoading = false)
                _users.value = emptyList()
                _pendingAccount.value = null
                resetVerificationState()
                
                onResult(DeleteAccountResult.Success)
            } catch (error: Exception) {
                val errorMsg = error.localizedMessage ?: "Failed to delete account"
                _sessionState.update { it.copy(errorMessage = errorMsg) }
                onResult(DeleteAccountResult.Error(errorMsg))
            }
        }
    }

    fun uploadProfilePhoto(imageBytes: ByteArray, onResult: (UpdateResult) -> Unit) {
        val user = _sessionState.value.user ?: run {
            onResult(UpdateResult.Error("User not found"))
            return
        }
        viewModelScope.launch {
            try {
                val url = repository.uploadProfilePhoto(user.uid, imageBytes)
                _sessionState.update { it.copy(user = user.copy(profilePic = url)) }
                onResult(UpdateResult.Success)
            } catch (error: Exception) {
                val errorMsg = error.localizedMessage ?: "Failed to upload profile picture"
                _sessionState.update { it.copy(errorMessage = errorMsg) }
                onResult(UpdateResult.Error(errorMsg))
            }
        }
    }

    fun removeProfilePhoto(onResult: (UpdateResult) -> Unit) {
        val user = _sessionState.value.user ?: run {
            onResult(UpdateResult.Error("User not found"))
            return
        }
        viewModelScope.launch {
            try {
                repository.removeProfilePhoto(user.uid)
                _sessionState.update { it.copy(user = user.copy(profilePic = "userDefault")) }
                onResult(UpdateResult.Success)
            } catch (error: Exception) {
                val errorMsg = error.localizedMessage ?: "Failed to remove profile picture"
                _sessionState.update { it.copy(errorMessage = errorMsg) }
                onResult(UpdateResult.Error(errorMsg))
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            try {
                oneSignalManager.logout()
            } catch (_: Exception) {
            }
            firebaseAuth.signOut()
            eventsListener?.remove()
            friendsListener?.remove()
            friendRequestsListener?.remove()
            friendRequestsSentListener?.remove()
            _sessionState.value = SessionState(isLoading = false)
            _users.value = emptyList()
            _pendingAccount.value = null
            resetVerificationState()
        }
    }
    
    fun getRepository(): CliqueRepository = repository
}
