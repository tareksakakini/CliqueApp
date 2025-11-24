package com.clique.app.data.repository.model

data class UserProfilePayload(
    val uid: String,
    val authUid: String,
    val phoneNumber: String,
    val fullName: String,
    val username: String,
    val gender: String
)
