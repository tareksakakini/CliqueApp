package com.clique.app.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.time.Instant

data class EventChatMessage(
    val id: String = "",
    val eventId: String = "",
    val senderId: String = "",
    val senderHandle: String = "",
    val senderName: String = "",
    val text: String = "",
    val createdAt: Instant = Instant.now()
) {
    companion object {
        fun fromSnapshot(snapshot: DocumentSnapshot): EventChatMessage? {
            val data = snapshot.data ?: return null
            val id = data["id"] as? String ?: snapshot.id
            val eventId = data["eventId"] as? String ?: ""
            val senderName = data["senderName"] as? String ?: ""
            val text = data["text"] as? String ?: ""
            
            val timestamp = data["createdAt"] as? Timestamp
            val createdAt = timestamp?.toDate()?.toInstant() ?: Instant.now()
            
            val senderId = data["senderId"] as? String 
                ?: data["senderUID"] as? String 
                ?: data["senderEmail"] as? String 
                ?: ""
            val senderHandle = data["senderEmail"] as? String ?: ""
            
            return EventChatMessage(
                id = id,
                eventId = eventId,
                senderId = senderId,
                senderHandle = senderHandle,
                senderName = senderName,
                text = text,
                createdAt = createdAt
            )
        }
    }
}

