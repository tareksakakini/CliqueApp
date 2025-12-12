package com.yallaconnect.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColors = darkColorScheme(
    primary = CliqueDarkPrimary,
    onPrimary = Color(0xFF0F1320),
    secondary = CliqueSecondary,
    background = Color(0xFF0F111A),
    surface = Color(0xFF171A23)
)

private val LightColors = lightColorScheme(
    primary = CliquePrimary,
    onPrimary = CliqueOnPrimary,
    secondary = CliqueSecondary,
    background = CliqueSurface,
    surface = Color.White
)

@Composable
fun CliqueTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColors else LightColors
    MaterialTheme(
        colorScheme = colorScheme,
        typography = MaterialTheme.typography,
        content = content
    )
}
