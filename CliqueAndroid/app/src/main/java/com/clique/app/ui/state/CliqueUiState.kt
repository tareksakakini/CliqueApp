package com.clique.app.ui.state

import android.os.Parcelable
import com.clique.app.data.model.Country
import com.clique.app.data.model.Event
import com.clique.app.data.model.User
import kotlinx.parcelize.Parcelize

@Parcelize
enum class AuthMode : Parcelable { SIGN_IN, SIGN_UP }

data class SessionState(
    val isLoading: Boolean = true,
    val user: User? = null,
    val events: List<Event> = emptyList(),
    val friendships: List<String> = emptyList(),
    val friendRequests: List<String> = emptyList(),
    val friendRequestsSent: List<String> = emptyList(),
    val errorMessage: String? = null
)

data class VerificationUiState(
    val verificationId: String? = null,
    val phoneNumber: String = "",
    val selectedCountry: Country = Country.default,
    val mode: AuthMode = AuthMode.SIGN_IN,
    val isSendingCode: Boolean = false,
    val isVerifyingCode: Boolean = false,
    val errorMessage: String? = null,
    val resendCountdown: Int = 0
)

data class PendingAccount(
    val authUid: String,
    val phoneNumber: String
)

sealed interface AccountCreationResult {
    data class Success(val user: User) : AccountCreationResult
    data class Error(val message: String) : AccountCreationResult
}

sealed interface UpdateResult {
    object Success : UpdateResult
    data class Error(val message: String) : UpdateResult
}

sealed interface DeleteAccountResult {
    object Success : DeleteAccountResult
    data class Error(val message: String) : DeleteAccountResult
}
