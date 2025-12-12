package com.yallaconnect.app.ui.navigation

import android.os.Parcelable
import com.yallaconnect.app.ui.state.AuthMode
import kotlinx.parcelize.Parcelize

@Parcelize
data class VerificationNavArgs(
    val verificationId: String,
    val phoneNumber: String,
    val mode: AuthMode
) : Parcelable
