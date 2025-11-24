package com.clique.app

import android.app.Application
import com.clique.app.core.AppContainer
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
