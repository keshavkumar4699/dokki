package dev.dokki.platform_android.keystore

import android.os.Handler
import android.os.Looper
import androidx.biometric.BiometricManager.Authenticators
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.util.concurrent.CompletableFuture

class UserCancelledException : Exception("user cancelled authentication")
class NoActivityException : Exception("no activity to show the auth prompt")

/**
 * Satisfies the Keystore's user-authentication gate (§8.3) with the
 * system prompt: biometric if enrolled, device credential otherwise. Runs
 * the prompt on the main thread and blocks the calling worker until the
 * user answers, so the Keystore op can simply be retried afterwards.
 */
class UserAuthGate(private val activityProvider: () -> FragmentActivity?) {
    private val main = Handler(Looper.getMainLooper())

    /** Runs [op]; if the Keystore demands authentication, prompts once and retries. */
    fun <T> withAuth(op: () -> T): T = try {
        op()
    } catch (e: UserAuthRequiredException) {
        authenticate()
        op()
    }

    private fun authenticate() {
        val activity = activityProvider() ?: throw NoActivityException()
        val done = CompletableFuture<Unit>()
        main.post {
            val prompt = BiometricPrompt(
                activity,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        done.complete(Unit)
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        done.completeExceptionally(UserCancelledException())
                    }
                },
            )
            prompt.authenticate(
                BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Unlock dokki")
                    .setSubtitle("Confirm it's you to use the vault key")
                    .setAllowedAuthenticators(Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL)
                    .build(),
            )
        }
        try {
            done.get()
        } catch (e: java.util.concurrent.ExecutionException) {
            throw e.cause ?: e
        }
    }
}
