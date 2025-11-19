package com.clique.app.ui.state

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.clique.app.core.auth.PhoneAuthManager
import com.clique.app.core.network.NetworkMonitor
import com.clique.app.core.notifications.NotificationRouter
import com.clique.app.core.notifications.OneSignalManager
import com.clique.app.core.util.PhoneNumberFormatter
import com.clique.app.data.model.Country
import com.clique.app.data.model.Event
import com.clique.app.data.model.EventChatMessage
import com.clique.app.data.model.User
import com.clique.app.data.repository.CliqueRepository
import com.clique.app.data.repository.model.FriendshipAction
import com.clique.app.data.repository.model.InviteAction
import com.clique.app.data.repository.model.UserProfilePayload
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthProvider
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
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
            oneSignalManager.login(user.uid)
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

    fun respondToInvite(eventId: String, action: InviteAction) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.respondToInvite(eventId, user.uid, action)
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun saveEvent(event: Event, isNew: Boolean, imageBytes: ByteArray?) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.upsertEvent(event, hostId = user.uid, selectedImage = imageBytes, isNewEvent = isNew)
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
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
                repository.sendEventChatMessage(eventId, user.uid, user.fullName, text)
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
                repository.sendFriendRequest(user.uid, receiver)
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun removeFriendRequest(receiver: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.removeFriendRequest(user.uid, receiver)
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
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun updateFullName(fullName: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.updateFullName(user.uid, fullName)
                _sessionState.update { it.copy(user = user.copy(fullName = fullName)) }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
            }
        }
    }

    fun updateUsername(username: String) {
        val user = _sessionState.value.user ?: return
        viewModelScope.launch {
            try {
                repository.updateUsername(user.uid, username)
                _sessionState.update { it.copy(user = user.copy(username = username)) }
            } catch (error: Exception) {
                _sessionState.update { it.copy(errorMessage = error.localizedMessage) }
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
}
