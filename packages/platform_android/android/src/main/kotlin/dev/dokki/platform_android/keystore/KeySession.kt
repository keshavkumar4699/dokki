package dev.dokki.platform_android.keystore

import dev.dokki.platform_android.crypto.Primitives
import dev.dokki.platform_android.crypto.TagVerificationFailed

/**
 * The native-side session (§8.2, §8.4): holds unwrapped master keys per
 * epoch and the DEKs currently bound for streaming, all as byte arrays
 * that are zeroed on lock/release. Nothing in here ever crosses the
 * method channel except the SQLCipher key, by design (§8.1 K_db).
 *
 * Key schedule — identical to `vault_crypto`'s `DartEnvelopePrimitive`:
 *   K_<purpose>(epoch) = HKDF(MK[epoch], salt=∅, "dokki/kek/v1/<epoch>/<purpose>")
 *   wrapped_dek        = nonce || AES-GCM(K_<purpose>, dek) || tag
 *   header_key         = HKDF(dek, salt, "dokki/envelope/v1/header")
 *   stream_key         = HKDF(dek, salt, "dokki/envelope/v1/stream")
 *   K_db               = HKDF(MK[active], salt=∅, "dokki/vault/kdb/v1")
 */
class KeySession {
    private val masterKeys = HashMap<Int, ByteArray>()
    private val deks = HashMap<Int, ByteArray>()
    private var nextKeyId = 1
    private var activeEpoch: Int? = null

    val isUnlocked: Boolean
        @Synchronized get() = masterKeys.isNotEmpty()

    @Synchronized
    fun bindMasterKey(epoch: Int, masterKey: ByteArray, active: Boolean) {
        masterKeys.remove(epoch)?.fill(0)
        masterKeys[epoch] = masterKey
        if (active) activeEpoch = epoch
    }

    @Synchronized
    fun masterKeyCopy(epoch: Int): ByteArray =
        masterKeys[epoch]?.copyOf() ?: throw LockedException()

    @Synchronized
    fun activeMasterKeyCopy(): ByteArray {
        val epoch = activeEpoch ?: throw LockedException()
        return masterKeyCopy(epoch)
    }

    /** Zeroes and drops every key. Best effort against JVM copies (§8.4). */
    @Synchronized
    fun lock() {
        masterKeys.values.forEach { it.fill(0) }
        masterKeys.clear()
        deks.values.forEach { it.fill(0) }
        deks.clear()
        activeEpoch = null
    }

    // ── Purpose keys and DEKs ───────────────────────────────────────────────

    private fun purposeKey(epoch: Int, purpose: Int): ByteArray {
        val mk = masterKeyCopy(epoch)
        try {
            return Primitives.hkdf(mk, ByteArray(0), "dokki/kek/v1/$epoch/$purpose".toByteArray())
        } finally {
            mk.fill(0)
        }
    }

    /** Fresh DEK, wrapped under K_<purpose>(epoch), bound → (wrapped, keyId). */
    fun generateAndBind(epoch: Int, purpose: Int): Pair<ByteArray, Int> {
        val dek = Primitives.randomBytes(32)
        val kek = purposeKey(epoch, purpose)
        try {
            val wrapped = Primitives.wrap(kek, dek)
            return wrapped to register(dek)
        } finally {
            kek.fill(0)
        }
    }

    fun bindWrapped(wrapped: ByteArray, epoch: Int, purpose: Int): Int {
        val kek = purposeKey(epoch, purpose)
        try {
            return register(Primitives.unwrap(kek, wrapped))
        } finally {
            kek.fill(0)
        }
    }

    @Synchronized
    private fun register(dek: ByteArray): Int {
        val id = nextKeyId++
        deks[id] = dek
        return id
    }

    @Synchronized
    fun release(keyId: Int) {
        deks.remove(keyId)?.fill(0)
    }

    @Synchronized
    private fun dek(keyId: Int): ByteArray = deks[keyId]?.copyOf() ?: throw LockedException()

    private fun subKey(keyId: Int, salt: ByteArray, label: String): ByteArray {
        val dek = dek(keyId)
        try {
            return Primitives.hkdf(dek, salt, label.toByteArray())
        } finally {
            dek.fill(0)
        }
    }

    fun sealHeader(keyId: Int, salt: ByteArray, aad: ByteArray): ByteArray {
        val key = subKey(keyId, salt, "dokki/envelope/v1/header")
        try {
            // Tag over empty plaintext, zero nonce: possession of the DEK is what
            // the tag proves (the Dart primitive does exactly this).
            return Primitives.gcmEncrypt(key, ByteArray(12), aad, ByteArray(0))
        } finally {
            key.fill(0)
        }
    }

    fun verifyHeader(keyId: Int, salt: ByteArray, aad: ByteArray, tag: ByteArray) {
        val key = subKey(keyId, salt, "dokki/envelope/v1/header")
        try {
            Primitives.gcmDecrypt(key, ByteArray(12), aad, tag)
        } finally {
            key.fill(0)
        }
    }

    fun encryptChunk(keyId: Int, salt: ByteArray, nonce: ByteArray, aad: ByteArray, plaintext: ByteArray): ByteArray {
        val key = subKey(keyId, salt, "dokki/envelope/v1/stream")
        try {
            return Primitives.gcmEncrypt(key, nonce, aad, plaintext)
        } finally {
            key.fill(0)
        }
    }

    fun decryptChunk(keyId: Int, salt: ByteArray, nonce: ByteArray, aad: ByteArray, ciphertext: ByteArray): ByteArray {
        if (ciphertext.size < 16) throw TagVerificationFailed()
        val key = subKey(keyId, salt, "dokki/envelope/v1/stream")
        try {
            return Primitives.gcmDecrypt(key, nonce, aad, ciphertext)
        } finally {
            key.fill(0)
        }
    }

    fun deriveDbKey(): ByteArray {
        val mk = activeMasterKeyCopy()
        try {
            return Primitives.hkdf(mk, ByteArray(0), "dokki/vault/kdb/v1".toByteArray())
        } finally {
            mk.fill(0)
        }
    }
}

class LockedException : Exception("vault locked")
