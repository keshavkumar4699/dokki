package dev.dokki.platform_android.crypto

import com.lambdapioneer.argon2kt.Argon2Kt
import com.lambdapioneer.argon2kt.Argon2Mode
import java.security.SecureRandom
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/** Raised on any AEAD tag mismatch: tamper, truncation, or a wrong key. */
class TagVerificationFailed : Exception("AEAD tag verification failed")

/**
 * The published primitives the architecture allows (§8.7 "We do not invent
 * cryptography"): HKDF-SHA256 (RFC 5869), AES-256-GCM (JCA, Conscrypt),
 * Argon2id (RFC 9106, reference C implementation via argon2kt).
 *
 * Every derivation label below must match `DartEnvelopePrimitive` in
 * `vault_crypto` byte for byte, because a file sealed by one backend has
 * to open under the other.
 */
object Primitives {
    private val random = SecureRandom()

    fun randomBytes(n: Int): ByteArray = ByteArray(n).also { random.nextBytes(it) }

    // ── HKDF-SHA256 ──────────────────────────────────────────────────────────

    fun hkdf(ikm: ByteArray, salt: ByteArray, info: ByteArray, length: Int = 32): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        // Extract: an empty salt is a string of HashLen zeros (RFC 5869 §2.2).
        val extractKey = if (salt.isEmpty()) ByteArray(32) else salt
        mac.init(SecretKeySpec(extractKey, "HmacSHA256"))
        val prk = mac.doFinal(ikm)
        // Expand.
        mac.init(SecretKeySpec(prk, "HmacSHA256"))
        val out = ByteArray(length)
        var previous = ByteArray(0)
        var written = 0
        var counter = 1
        while (written < length) {
            mac.update(previous)
            mac.update(info)
            mac.update(counter.toByte())
            previous = mac.doFinal()
            val take = minOf(previous.size, length - written)
            System.arraycopy(previous, 0, out, written, take)
            written += take
            counter++
        }
        prk.fill(0)
        return out
    }

    // ── AES-256-GCM ──────────────────────────────────────────────────────────

    /** `ciphertext || tag(16)`, exactly what JCA produces. */
    fun gcmEncrypt(key: ByteArray, nonce: ByteArray, aad: ByteArray, plaintext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, nonce))
        if (aad.isNotEmpty()) cipher.updateAAD(aad)
        return cipher.doFinal(plaintext)
    }

    fun gcmDecrypt(key: ByteArray, nonce: ByteArray, aad: ByteArray, ciphertextAndTag: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, nonce))
        if (aad.isNotEmpty()) cipher.updateAAD(aad)
        return try {
            cipher.doFinal(ciphertextAndTag)
        } catch (e: AEADBadTagException) {
            throw TagVerificationFailed()
        }
    }

    /** `nonce(12) || ct || tag` — the wrapped-key layout shared with Dart. */
    fun wrap(key: ByteArray, plaintext: ByteArray): ByteArray {
        val nonce = randomBytes(12)
        return nonce + gcmEncrypt(key, nonce, ByteArray(0), plaintext)
    }

    fun unwrap(key: ByteArray, wrapped: ByteArray): ByteArray {
        if (wrapped.size < 12 + 16) throw TagVerificationFailed()
        return gcmDecrypt(key, wrapped.copyOfRange(0, 12), ByteArray(0), wrapped.copyOfRange(12, wrapped.size))
    }

    // ── Argon2id ─────────────────────────────────────────────────────────────

    data class Argon2Params(val memoryKiB: Int, val iterations: Int, val parallelism: Int)

    /** PIN path (§15.3): m=64 MiB, t=3, p=2. */
    val pinParams = Argon2Params(memoryKiB = 64 * 1024, iterations = 3, parallelism = 2)

    /** Recovery path (§8.2): m=256 MiB, t=4, p=2. */
    val recoveryParams = Argon2Params(memoryKiB = 256 * 1024, iterations = 4, parallelism = 2)

    private val argon2 by lazy { Argon2Kt() }

    fun argon2id(secret: String, salt: ByteArray, params: Argon2Params): ByteArray {
        val result = argon2.hash(
            mode = Argon2Mode.ARGON2_ID,
            password = secret.toByteArray(Charsets.UTF_8),
            salt = salt,
            tCostInIterations = params.iterations,
            mCostInKibibyte = params.memoryKiB,
            parallelism = params.parallelism,
            hashLengthInBytes = 32,
        )
        return result.rawHashAsByteArray()
    }
}
