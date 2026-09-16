package dev.dokki.platform_android.keystore

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import android.security.keystore.UserNotAuthenticatedException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class NoDeviceLockException : Exception("no secure lock screen")
class KeyInvalidatedException : Exception("keystore key invalidated")
class UserAuthRequiredException : Exception("user authentication required")

/**
 * The hardware-bound KEK (§8.3): one AES-256-GCM Keystore key per epoch,
 * `vault.kek.<epoch>`, non-exportable, auth-bound, StrongBox when the
 * device has it.
 *
 * Deviation from §8.3 (documented): user authentication is bound with a
 * validity window rather than per-use (`setUserAuthenticationParameters(0,…)`),
 * because per-use requires the CryptoObject prompt flow for every unwrap;
 * a 30 s window lets the PIN screen authenticate once and unwrap every
 * epoch in one go. Both factors remain mandatory: the Keystore gate and the
 * PIN-derived HKDF salt (§8.2).
 */
class KeystoreKek(private val context: Context) {
    companion object {
        private const val PROVIDER = "AndroidKeyStore"
        const val AUTH_VALIDITY_SECONDS = 30

        fun aliasFor(epoch: Int) = "vault.kek.$epoch"
    }

    private val keyStore: KeyStore = KeyStore.getInstance(PROVIDER).apply { load(null) }

    fun hasDeviceLock(): Boolean =
        (context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)?.isDeviceSecure == true

    /** Creates the KEK for [alias]. Returns whether it landed in StrongBox. */
    fun create(alias: String): Boolean {
        if (!hasDeviceLock()) throw NoDeviceLockException()
        return try {
            generate(alias, strongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
        } catch (e: StrongBoxUnavailableException) {
            // §8.3: most devices have no StrongBox; fall back to the TEE.
            generate(alias, strongBox = false)
            false
        }
    }

    private fun generate(alias: String, strongBox: Boolean) {
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setRandomizedEncryptionRequired(true)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUserAuthenticationParameters(
                AUTH_VALIDITY_SECONDS,
                KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL,
            )
        } else {
            @Suppress("DEPRECATION")
            builder.setUserAuthenticationValidityDurationSeconds(AUTH_VALIDITY_SECONDS)
        }
        if (strongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }
        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER).run {
            init(builder.build())
            generateKey()
        }
    }

    private fun key(alias: String): SecretKey =
        (keyStore.getKey(alias, null) as? SecretKey) ?: throw KeyInvalidatedException()

    /** `iv(12) || ct || tag` under the Keystore key. */
    fun encrypt(alias: String, plaintext: ByteArray): ByteArray = guarded {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key(alias))
        cipher.iv + cipher.doFinal(plaintext)
    }

    fun decrypt(alias: String, wrapped: ByteArray): ByteArray = guarded {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(alias), GCMParameterSpec(128, wrapped.copyOfRange(0, 12)))
        cipher.doFinal(wrapped.copyOfRange(12, wrapped.size))
    }

    fun delete(alias: String) {
        if (keyStore.containsAlias(alias)) keyStore.deleteEntry(alias)
    }

    private inline fun <T> guarded(block: () -> T): T = try {
        block()
    } catch (e: UserNotAuthenticatedException) {
        throw UserAuthRequiredException()
    } catch (e: KeyPermanentlyInvalidatedException) {
        throw KeyInvalidatedException()
    }
}
