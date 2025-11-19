package com.clique.app.core

import android.app.Application
import com.clique.app.core.auth.PhoneAuthManager
import com.clique.app.core.network.NetworkMonitor
import com.clique.app.core.notifications.NotificationRouter
import com.clique.app.core.notifications.OneSignalManager
import com.clique.app.data.repository.CliqueRepository
import com.clique.app.data.repository.FirebaseCliqueRepository
import com.google.firebase.auth.FirebaseAuth

class AppContainer(application: Application) {
    val firebaseAuth: FirebaseAuth = FirebaseAuth.getInstance()
    val repository: CliqueRepository = FirebaseCliqueRepository()
    val notificationRouter = NotificationRouter()
    val networkMonitor = NetworkMonitor(application)
    val phoneAuthManager = PhoneAuthManager(firebaseAuth)
    val oneSignalManager = OneSignalManager(application, notificationRouter)
}
