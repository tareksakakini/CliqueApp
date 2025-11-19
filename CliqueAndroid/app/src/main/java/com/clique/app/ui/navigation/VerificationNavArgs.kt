package com.clique.app.ui.navigation

import android.os.Parcelable
import com.clique.app.ui.state.AuthMode
import kotlinx.parcelize.Parcelize

@Parcelize
data class VerificationNavArgs(
    val verificationId: String,
    val phoneNumber: String,
    val mode: AuthMode
) : Parcelable
