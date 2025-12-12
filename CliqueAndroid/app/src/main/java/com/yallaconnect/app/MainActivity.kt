package com.yallaconnect.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import com.yallaconnect.app.ui.navigation.CliqueNavHost
import com.yallaconnect.app.ui.state.CliqueAppViewModel
import com.yallaconnect.app.ui.state.CliqueAppViewModelFactory
import com.yallaconnect.app.ui.theme.CliqueTheme
import com.yallaconnect.app.core.AppContainer

val LocalAppContainer = staticCompositionLocalOf<AppContainer> { error("AppContainer not provided") }

class MainActivity : ComponentActivity() {
    private val appContainer by lazy { (application as CliqueAndroidApp).container }
    private val viewModel: CliqueAppViewModel by viewModels { CliqueAppViewModelFactory(appContainer) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            CliqueTheme {
                CompositionLocalProvider(LocalAppContainer provides appContainer) {
                    CliqueNavHost(viewModel = viewModel)
                }
            }
        }
    }
}
