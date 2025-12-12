package com.yallaconnect.app.core

import android.app.Application
import com.yallaconnect.app.core.auth.PhoneAuthManager
import com.yallaconnect.app.core.network.NetworkMonitor
import com.yallaconnect.app.core.notifications.NotificationRouter
import com.yallaconnect.app.core.notifications.OneSignalManager
import com.yallaconnect.app.data.repository.CliqueRepository
import com.yallaconnect.app.data.repository.FirebaseCliqueRepository
import com.google.firebase.auth.FirebaseAuth

class AppContainer(application: Application) {
    val firebaseAuth: FirebaseAuth = FirebaseAuth.getInstance()
    val repository: CliqueRepository = FirebaseCliqueRepository()
    val notificationRouter = NotificationRouter()
    val networkMonitor = NetworkMonitor(application)
    val phoneAuthManager = PhoneAuthManager(firebaseAuth)
    val oneSignalManager = OneSignalManager(application, notificationRouter)
}
