package com.clique.app.ui.navigation

import androidx.navigation.NavController

fun NavController.navigateAndPopUp(route: String) {
    navigate(route) {
        popUpTo(graph.startDestinationId) {
            inclusive = true
        }
        launchSingleTop = true
    }
}
