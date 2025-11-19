package com.clique.app.ui.navigation

import android.app.Activity
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.clique.app.data.repository.model.FriendshipAction
import com.clique.app.data.repository.model.InviteAction
import com.clique.app.ui.screens.account.AccountInfoScreen
import com.clique.app.ui.screens.auth.LoginScreen
import com.clique.app.ui.screens.auth.SignUpScreen
import com.clique.app.ui.screens.auth.VerificationScreen
import com.clique.app.ui.screens.main.MainScreen
import com.clique.app.ui.screens.starting.StartingScreen
import com.clique.app.ui.state.AuthMode
import com.clique.app.ui.state.CliqueAppViewModel
import com.clique.app.ui.state.AccountCreationResult

@Composable
fun CliqueNavHost(
    viewModel: CliqueAppViewModel,
    modifier: Modifier = Modifier
) {
    val navController = rememberNavController()
    val session by viewModel.sessionState.collectAsStateWithLifecycle()
    val verificationState by viewModel.verificationState.collectAsStateWithLifecycle()
    val pendingAccount by viewModel.pendingAccount.collectAsStateWithLifecycle()
    val users by viewModel.users.collectAsStateWithLifecycle()
    val verificationRoute = "${CliqueDestination.Verification.route}?$ARG_VERIFICATION_ID={$ARG_VERIFICATION_ID}&$ARG_PHONE={$ARG_PHONE}&$ARG_MODE={$ARG_MODE}"
    val accountRoute = "${CliqueDestination.AccountInfo.route}?$ACCOUNT_PHONE_KEY={$ACCOUNT_PHONE_KEY}"

    NavHost(
        navController = navController,
        startDestination = CliqueDestination.Starting.route,
        modifier = modifier
    ) {
        composable(CliqueDestination.Starting.route) {
            StartingScreen(
                isLoading = session.isLoading,
                onLogin = {
                    viewModel.resetVerificationState()
                    navController.navigate(CliqueDestination.Login.route)
                },
                onSignUp = {
                    viewModel.resetVerificationState()
                    navController.navigate(CliqueDestination.SignUp.route)
                }
            )
            LaunchedEffect(session.isLoading, session.user) {
                if (!session.isLoading && session.user != null) {
                    navController.navigateAndPopUp(CliqueDestination.Main.route)
                }
            }
        }
        composable(CliqueDestination.Login.route) {
            LoginScreen(
                state = verificationState,
                onSendCode = { activity, raw, country ->
                    viewModel.sendVerificationCode(activity, raw, country, AuthMode.SIGN_IN)
                },
                onNavigateToVerification = { verificationId, phone, mode ->
                    val route = "${CliqueDestination.Verification.route}?$ARG_VERIFICATION_ID=${Uri.encode(verificationId)}&$ARG_PHONE=${Uri.encode(phone)}&$ARG_MODE=${mode.name}"
                    navController.navigate(route)
                },
                onGoToSignUp = {
                    viewModel.resetVerificationState()
                    navController.navigate(CliqueDestination.SignUp.route)
                }
            )
        }
        composable(CliqueDestination.SignUp.route) {
            SignUpScreen(
                state = verificationState,
                onSendCode = { activity, raw, country ->
                    viewModel.sendVerificationCode(activity, raw, country, AuthMode.SIGN_UP)
                },
                onNavigateToVerification = { verificationId, phone, mode ->
                    val route = "${CliqueDestination.Verification.route}?$ARG_VERIFICATION_ID=${Uri.encode(verificationId)}&$ARG_PHONE=${Uri.encode(phone)}&$ARG_MODE=${mode.name}"
                    navController.navigate(route)
                },
                onLogin = {
                    viewModel.resetVerificationState()
                    navController.navigate(CliqueDestination.Login.route)
                }
            )
        }
        composable(
            route = verificationRoute,
            arguments = listOf(
                navArgument(ARG_VERIFICATION_ID) { type = NavType.StringType },
                navArgument(ARG_PHONE) { type = NavType.StringType },
                navArgument(ARG_MODE) { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val context = LocalContext.current
            val verificationId = backStackEntry.arguments?.getString(ARG_VERIFICATION_ID).orEmpty()
            val phone = backStackEntry.arguments?.getString(ARG_PHONE).orEmpty()
            val mode = backStackEntry.arguments?.getString(ARG_MODE)?.let { AuthMode.valueOf(it) } ?: AuthMode.SIGN_IN
            VerificationScreen(
                state = verificationState.copy(phoneNumber = phone, mode = mode),
                onVerify = { code, authMode ->
                    viewModel.verifyCode(verificationId, code, authMode)
                },
                onBack = {
                    navController.popBackStack()
                },
                onResendCode = { activity ->
                    viewModel.resendVerificationCode(activity)
                }
            )
            if (pendingAccount != null && mode == AuthMode.SIGN_UP) {
                val accountRouteWithPhone = "${CliqueDestination.AccountInfo.route}?$ACCOUNT_PHONE_KEY=${Uri.encode(phone)}"
                LaunchedEffect(pendingAccount) {
                    navController.navigate(accountRouteWithPhone)
                }
            } else if (session.user != null && mode == AuthMode.SIGN_IN) {
                LaunchedEffect(session.user) {
                    navController.navigateAndPopUp(CliqueDestination.Main.route)
                }
            }
        }
        composable(
            route = accountRoute,
            arguments = listOf(navArgument(ACCOUNT_PHONE_KEY) { type = NavType.StringType })
        ) { backStackEntry ->
            val phone = backStackEntry.arguments?.getString(ACCOUNT_PHONE_KEY).orEmpty()
            val localError = remember { mutableStateOf<String?>(null) }
            val submitting = remember { mutableStateOf(false) }
            AccountInfoScreen(
                phoneNumber = phone,
                errorMessage = localError.value,
                isSubmitting = submitting.value,
                onSubmit = { fullName, username, gender ->
                    submitting.value = true
                    viewModel.completeAccountCreation(fullName, username, gender) { result ->
                        submitting.value = false
                        when (result) {
                            is AccountCreationResult.Success -> {
                                navController.navigateAndPopUp(CliqueDestination.Main.route)
                            }
                            is AccountCreationResult.Error -> localError.value = result.message
                        }
                    }
                },
                onViewPolicy = { }
            )
        }
        composable(CliqueDestination.Main.route) {
            if (session.user == null) {
                LaunchedEffect(Unit) {
                    navController.navigateAndPopUp(CliqueDestination.Starting.route)
                }
            } else {
                MainScreen(
                    session = session,
                    users = users,
                    onRespondToInvite = { eventId, action -> viewModel.respondToInvite(eventId, action) },
                    onSaveEvent = { event -> viewModel.saveEvent(event, isNew = true, imageBytes = null) },
                    onSendFriendRequest = viewModel::sendFriendRequest,
                    onRemoveRequest = viewModel::removeFriendRequest,
                    onFriendshipUpdate = viewModel::updateFriendship,
                    onUpdateFullName = viewModel::updateFullName,
                    onUpdateUsername = viewModel::updateUsername,
                    onSignOut = viewModel::signOut
                )
            }
        }
    }
}
