package dev.dokki.platform_android.keystore

import android.util.Base64
import dev.dokki.platform_android.crypto.Primitives
import dev.dokki.platform_android.crypto.TagVerificationFailed
import org.json.JSONObject

class AuthFailedException : Exception("wrong PIN or passphrase")

/**
 * How the master key is wrapped for `wrap_alg = KEYSTORE_AES_GCM_V1` (§8.1):
 *
 *   device_secret  = 32 random bytes, kept ONLY Keystore-encrypted
 *   KEK            = HKDF(ikm = device_secret,
 *                         salt = Argon2id(pin, pin_salt),
 *                         info = "dokki/kek/v1/<epoch>")
 *   wrapped_mk_device = 0x01 || ks_iv(12) || ks_ct(32+16) || nonce(12) || AES-GCM(KEK, MK)(32+16)
 *
 *   KEK_recovery   = Argon2id(passphrase, recovery_salt)   (m=256 MiB)
 *   wrapped_mk_recovery = nonce(12) || AES-GCM(KEK_recovery, MK)(32+16)
 *
 * The PIN alone yields nothing without the Keystore (device_secret is only
 * ever decrypted by the hardware, after user auth); the Keystore alone
 * yields nothing without the PIN (wrong salt → wrong KEK → GCM fails).
 * That is M1 avoided by construction (§8.2).
 */
class MasterKeyWrap(private val keystore: KeystoreKek) {
    companion object {
        const val ALG = "KEYSTORE_AES_GCM_V1"
        private const val VERSION: Byte = 1
        private const val KS_BLOB = 12 + 32 + 16
        private const val MK_BLOB = 12 + 32 + 16
    }

    class KdfParams(val pin: Primitives.Argon2Params, val pinSalt: ByteArray, val recovery: Primitives.Argon2Params, val recoverySalt: ByteArray) {
        fun toJson(): String = JSONObject()
            .put("alg", ALG)
            .put("pin", JSONObject().put("m", pin.memoryKiB).put("t", pin.iterations).put("p", pin.parallelism)
                .put("salt", Base64.encodeToString(pinSalt, Base64.NO_WRAP)))
            .put("recovery", JSONObject().put("m", recovery.memoryKiB).put("t", recovery.iterations).put("p", recovery.parallelism)
                .put("salt", Base64.encodeToString(recoverySalt, Base64.NO_WRAP)))
            .toString()

        fun withRecoverySalt(salt: ByteArray) = KdfParams(pin, pinSalt, recovery, salt)

        companion object {
            fun fresh() = KdfParams(Primitives.pinParams, Primitives.randomBytes(16), Primitives.recoveryParams, Primitives.randomBytes(16))

            fun parse(json: String): KdfParams {
                val o = JSONObject(json)
                fun params(key: String) = o.getJSONObject(key).let {
                    Primitives.Argon2Params(it.getInt("m"), it.getInt("t"), it.getInt("p")) to
                        Base64.decode(it.getString("salt"), Base64.NO_WRAP)
                }
                val (pin, pinSalt) = params("pin")
                val (recovery, recoverySalt) = params("recovery")
                return KdfParams(pin, pinSalt, recovery, recoverySalt)
            }
        }
    }

    class Wrapped(val device: ByteArray, val recovery: ByteArray, val params: KdfParams, val alias: String, val strongBox: Boolean)

    /** Wraps [masterKey] under a NEW Keystore KEK for [epoch] plus the passphrase. */
    fun wrapNew(epoch: Int, masterKey: ByteArray, pin: String, passphrase: String): Wrapped {
        val alias = KeystoreKek.aliasFor(epoch)
        keystore.delete(alias)
        val strongBox = keystore.create(alias)
        val params = KdfParams.fresh()
        val deviceSecret = Primitives.randomBytes(32)
        try {
            val ksBlob = keystore.encrypt(alias, deviceSecret)
            check(ksBlob.size == KS_BLOB) { "unexpected keystore blob size ${ksBlob.size}" }
            val kek = deriveKek(epoch, deviceSecret, pin, params)
            val mkBlob = try { Primitives.wrap(kek, masterKey) } finally { kek.fill(0) }
            val device = byteArrayOf(VERSION) + ksBlob + mkBlob
            return Wrapped(device, wrapRecovery(masterKey, passphrase, params), params, alias, strongBox)
        } finally {
            deviceSecret.fill(0)
        }
    }

    /** Unwraps MK from the device blob. Wrong PIN → [AuthFailedException]. */
    fun unwrapDevice(epoch: Int, alias: String, wrapped: ByteArray, pin: String, params: KdfParams): ByteArray {
        if (wrapped.size != 1 + KS_BLOB + MK_BLOB || wrapped[0] != VERSION) throw AuthFailedException()
        val ksBlob = wrapped.copyOfRange(1, 1 + KS_BLOB)
        val mkBlob = wrapped.copyOfRange(1 + KS_BLOB, wrapped.size)
        val deviceSecret = keystore.decrypt(alias, ksBlob)
        try {
            val kek = deriveKek(epoch, deviceSecret, pin, params)
            try {
                return Primitives.unwrap(kek, mkBlob)
            } catch (e: TagVerificationFailed) {
                throw AuthFailedException()
            } finally {
                kek.fill(0)
            }
        } finally {
            deviceSecret.fill(0)
        }
    }

    fun wrapRecovery(masterKey: ByteArray, passphrase: String, params: KdfParams): ByteArray {
        val kek = Primitives.argon2id(passphrase, params.recoverySalt, params.recovery)
        try {
            return Primitives.wrap(kek, masterKey)
        } finally {
            kek.fill(0)
        }
    }

    fun unwrapRecovery(wrapped: ByteArray, passphrase: String, params: KdfParams): ByteArray {
        val kek = Primitives.argon2id(passphrase, params.recoverySalt, params.recovery)
        try {
            return Primitives.unwrap(kek, wrapped)
        } catch (e: TagVerificationFailed) {
            throw AuthFailedException()
        } finally {
            kek.fill(0)
        }
    }

    private fun deriveKek(epoch: Int, deviceSecret: ByteArray, pin: String, params: KdfParams): ByteArray {
        val salt = Primitives.argon2id(pin, params.pinSalt, params.pin)
        try {
            return Primitives.hkdf(deviceSecret, salt, "dokki/kek/v1/$epoch".toByteArray())
        } finally {
            salt.fill(0)
        }
    }
}
