package com.clique.app.data.model

import com.clique.app.core.util.PhoneNumberFormatter
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot

private typealias UserId = String

data class User(
    val uid: UserId = "",
    val authUid: String = "",
    val fullName: String = "",
    val username: String = "",
    val createdAt: Timestamp? = null,
    val profilePic: String = "",
    val gender: String = "",
    val phoneNumber: String = ""
) {
    val identifierCandidates: Set<String>
        get() = buildSet {
            if (uid.isNotBlank()) add(uid)
            if (authUid.isNotBlank()) add(authUid)
        }

    val phoneNumberE164: String
        get() = PhoneNumberFormatter.e164(phoneNumber).ifBlank { phoneNumber }

    fun matchesIdentifier(identifier: String): Boolean {
        if (identifier.isBlank()) return false
        return identifier == uid || identifier == authUid
    }

    fun toFirestore() = mapOf(
        "uid" to uid,
        "authUID" to authUid,
        "fullname" to fullName,
        "username" to username,
        "createdAt" to (createdAt ?: Timestamp.now()),
        "profilePic" to profilePic,
        "gender" to gender,
        "phoneNumber" to phoneNumberE164.ifBlank { phoneNumber }
    )

    companion object {
        fun fromSnapshot(snapshot: DocumentSnapshot): User {
            val data = snapshot.data ?: emptyMap<String, Any?>()
            return User(
                uid = data["uid"] as? String ?: snapshot.id,
                authUid = data["authUID"] as? String ?: "",
                fullName = data["fullname"] as? String ?: "",
                username = data["username"] as? String ?: "",
                createdAt = data["createdAt"] as? Timestamp,
                profilePic = data["profilePic"] as? String ?: "",
                gender = data["gender"] as? String ?: "",
                phoneNumber = PhoneNumberFormatter.e164(data["phoneNumber"] as? String ?: "")
                    .ifBlank { data["phoneNumber"] as? String ?: "" }
            )
        }
    }
}
