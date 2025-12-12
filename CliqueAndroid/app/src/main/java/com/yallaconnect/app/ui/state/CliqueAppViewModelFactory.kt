package com.yallaconnect.app.ui.state

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.yallaconnect.app.core.AppContainer

class CliqueAppViewModelFactory(
    private val container: AppContainer
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CliqueAppViewModel::class.java)) {
            return CliqueAppViewModel(
                repository = container.repository,
                phoneAuthManager = container.phoneAuthManager,
                networkMonitor = container.networkMonitor,
                notificationRouter = container.notificationRouter,
                oneSignalManager = container.oneSignalManager,
                firebaseAuth = container.firebaseAuth
            ) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class ${modelClass.name}")
    }
}
