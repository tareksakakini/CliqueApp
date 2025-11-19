package com.clique.app.ui.navigation

sealed class CliqueDestination(val route: String) {
    data object Starting : CliqueDestination("starting")
    data object Login : CliqueDestination("login")
    data object SignUp : CliqueDestination("signup")
    data object Verification : CliqueDestination("verification")
    data object AccountInfo : CliqueDestination("account_info")
    data object Main : CliqueDestination("main")
    data object EventDetail : CliqueDestination("event_detail")
    data object EventChat : CliqueDestination("event_chat")
}

const val VERIFICATION_ARGS_KEY = "verification_args"
const val ACCOUNT_PHONE_KEY = "account_phone"
const val ARG_VERIFICATION_ID = "verificationId"
const val ARG_PHONE = "phone"
const val ARG_MODE = "mode"
const val ARG_EVENT_ID = "eventId"
const val ARG_INVITE_VIEW = "inviteView"
const val ARG_CHAT_EVENT_ID = "chatEventId"
