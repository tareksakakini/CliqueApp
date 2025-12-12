package com.yallaconnect.app

import android.app.Application
import com.yallaconnect.app.core.AppContainer
import com.google.firebase.FirebaseApp

class CliqueAndroidApp : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        container = AppContainer(this)
        container.oneSignalManager.initialize()
    }
}
