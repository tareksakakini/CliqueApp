package com.yallaconnect.app.core.auth

import android.app.Activity
import com.google.firebase.FirebaseException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthOptions
import com.google.firebase.auth.PhoneAuthProvider
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

data class VerificationResult(
    val verificationId: String,
    val resendToken: PhoneAuthProvider.ForceResendingToken
)

class PhoneAuthManager(private val auth: FirebaseAuth) {

    suspend fun sendVerificationCode(activity: Activity, phoneNumber: String): VerificationResult =
        suspendCancellableCoroutine { continuation ->
            val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
                override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                    // Auto-retrieval is better handled by asking the caller to use the returned credential manually
                }

                override fun onVerificationFailed(e: FirebaseException) {
                    if (continuation.isActive) {
                        continuation.resumeWithException(e)
                    }
                }

                override fun onCodeSent(verificationId: String, token: PhoneAuthProvider.ForceResendingToken) {
                    if (continuation.isActive) {
                        continuation.resume(VerificationResult(verificationId, token))
                    }
                }
            }

            val options = PhoneAuthOptions.newBuilder(auth)
                .setPhoneNumber(phoneNumber)
                .setTimeout(60L, TimeUnit.SECONDS)
                .setActivity(activity)
                .setCallbacks(callbacks)
                .build()

            PhoneAuthProvider.verifyPhoneNumber(options)

            continuation.invokeOnCancellation {
                // No-op; Firebase SDK handles cleanup.
            }
        }

    suspend fun resendVerificationCode(
        activity: Activity,
        phoneNumber: String,
        token: PhoneAuthProvider.ForceResendingToken
    ): VerificationResult =
        suspendCancellableCoroutine { continuation ->
            val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
                override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                    // Auto-retrieval is better handled by asking the caller to use the returned credential manually
                }

                override fun onVerificationFailed(e: FirebaseException) {
                    if (continuation.isActive) {
                        continuation.resumeWithException(e)
                    }
                }

                override fun onCodeSent(verificationId: String, newToken: PhoneAuthProvider.ForceResendingToken) {
                    if (continuation.isActive) {
                        continuation.resume(VerificationResult(verificationId, newToken))
                    }
                }
            }

            val options = PhoneAuthOptions.newBuilder(auth)
                .setPhoneNumber(phoneNumber)
                .setTimeout(60L, TimeUnit.SECONDS)
                .setActivity(activity)
                .setCallbacks(callbacks)
                .setForceResendingToken(token)
                .build()

            PhoneAuthProvider.verifyPhoneNumber(options)

            continuation.invokeOnCancellation {
                // No-op; Firebase SDK handles cleanup.
            }
        }

    suspend fun verifyCode(verificationId: String, code: String): FirebaseUser =
        suspendCancellableCoroutine { continuation ->
            val credential = PhoneAuthProvider.getCredential(verificationId, code)
            auth.signInWithCredential(credential).addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val user = task.result?.user
                    if (user != null) {
                        continuation.resume(user)
                    } else {
                        continuation.resumeWithException(IllegalStateException("User missing from Firebase response"))
                    }
                } else {
                    continuation.resumeWithException(task.exception ?: IllegalStateException("Verification failed"))
                }
            }
        }
}
