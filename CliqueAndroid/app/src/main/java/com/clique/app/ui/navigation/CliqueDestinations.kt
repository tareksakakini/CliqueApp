package com.clique.app.ui.navigation

sealed class CliqueDestination(val route: String) {
    data object Starting : CliqueDestination("starting")
    data object Login : CliqueDestination("login")
    data object SignUp : CliqueDestination("signup")
    data object Verification : CliqueDestination("verification")
    data object AccountInfo : CliqueDestination("account_info")
    data object Main : CliqueDestination("main")
}

const val VERIFICATION_ARGS_KEY = "verification_args"
const val ACCOUNT_PHONE_KEY = "account_phone"
const val ARG_VERIFICATION_ID = "verificationId"
const val ARG_PHONE = "phone"
const val ARG_MODE = "mode"
