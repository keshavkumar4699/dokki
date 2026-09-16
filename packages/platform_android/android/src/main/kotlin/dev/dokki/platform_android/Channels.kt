package dev.dokki.platform_android

import android.os.Handler
import android.os.Looper
import android.util.Base64
import dev.dokki.platform_android.crypto.EnvelopeFormatException
import dev.dokki.platform_android.crypto.EnvelopePurposeMismatch
import dev.dokki.platform_android.crypto.Primitives
import dev.dokki.platform_android.crypto.TagVerificationFailed
import dev.dokki.platform_android.imaging.DecodeTooLargeException
import dev.dokki.platform_android.imaging.NativeImaging
import dev.dokki.platform_android.imaging.UndecodableImageException
import dev.dokki.platform_android.imaging.UnsupportedOpException
import dev.dokki.platform_android.keystore.AuthFailedException
import dev.dokki.platform_android.keystore.KeyInvalidatedException
import dev.dokki.platform_android.keystore.KeySession
import dev.dokki.platform_android.keystore.KeystoreKek
import dev.dokki.platform_android.keystore.LockedException
import dev.dokki.platform_android.keystore.MasterKeyWrap
import dev.dokki.platform_android.keystore.NoActivityException
import dev.dokki.platform_android.keystore.NoDeviceLockException
import dev.dokki.platform_android.keystore.UserAuthGate
import dev.dokki.platform_android.keystore.UserCancelledException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Runs channel handlers off the main thread (Argon2 takes seconds, AES on
 * 256 KiB chunks is not free) and answers on it, translating exceptions to
 * the stable error codes the Dart `guardChannel` understands (§12.6).
 * Kotlin never sends a human-readable message.
 */
abstract class WorkerChannel : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    abstract fun handle(call: MethodCall): Any?

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            val outcome = runCatching { handle(call) }
            main.post {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { e ->
                        if (e is NotImplementedError) result.notImplemented()
                        else result.error(codeFor(e), null, null)
                    },
                )
            }
        }
    }

    private fun codeFor(e: Throwable): String = when (e) {
        is TagVerificationFailed -> "TAG_VERIFICATION_FAILED"
        is AuthFailedException -> "AUTH_FAILED"
        is KeyInvalidatedException -> "KEY_INVALIDATED"
        is NoDeviceLockException -> "NO_DEVICE_LOCK"
        is UserCancelledException, is NoActivityException -> "USER_CANCELLED"
        is LockedException -> "LOCKED"
        is EnvelopeFormatException, is EnvelopePurposeMismatch -> "ENVELOPE_FORMAT"
        is UndecodableImageException -> "UNSUPPORTED_FORMAT"
        is DecodeTooLargeException -> "DECODE_TOO_LARGE"
        is UnsupportedOpException -> "UNSUPPORTED_OP"
        is OutOfMemoryError -> "OUT_OF_MEMORY"
        is java.io.IOException -> "STORAGE_IO"
        else -> "NATIVE_${e::class.java.simpleName.uppercase()}"
    }

    fun shutdown() = worker.shutdownNow()

    protected fun MethodCall.bytes(key: String): ByteArray = Base64.decode(argument<String>(key)!!, Base64.NO_WRAP)
    protected fun MethodCall.string(key: String): String = argument<String>(key)!!
    protected fun MethodCall.int(key: String): Int = argument<Int>(key)!!
    protected fun ByteArray.b64(): String = Base64.encodeToString(this, Base64.NO_WRAP)
}

/** `dokki/vault_keymanager` — see the Dart `NativeKeyManagerBridge` for the protocol. */
class KeyManagerChannel(
    private val session: KeySession,
    private val keystore: KeystoreKek,
    private val gate: UserAuthGate,
) : WorkerChannel() {
    private val wrap = MasterKeyWrap(keystore)

    override fun handle(call: MethodCall): Any? = when (call.method) {
        "isUnlocked" -> session.isUnlocked
        "lock" -> { session.lock(); null }
        "createVault" -> createVault(call)
        "unlock" -> unlock(call)
        "verifyPin" -> verifyPin(call)
        "verifyRecoveryPassphrase" -> verifyRecovery(call)
        "changeRecovery" -> changeRecovery(call)
        "deriveDbKey" -> mapOf("key" to session.deriveDbKey().b64())
        "importUnwrapped" -> importUnwrapped(call)
        else -> throw NotImplementedError()
    }

    private fun createVault(call: MethodCall): Map<String, Any?> {
        if (!keystore.hasDeviceLock()) throw NoDeviceLockException()
        val epoch = call.int("epoch")
        val mk = Primitives.randomBytes(32)
        val wrapped = gate.withAuth { wrap.wrapNew(epoch, mk, call.string("pin"), call.string("recoveryPassphrase")) }
        session.bindMasterKey(epoch, mk, active = true)
        return wrapped.toMap()
    }

    private fun unlock(call: MethodCall): Any? {
        val pin = call.string("pin")
        val epochs = call.argument<List<Map<String, Any?>>>("epochs")!!
        val unwrapped = ArrayList<Pair<Int, ByteArray>>()
        try {
            for (e in epochs) {
                val epoch = e["epoch"] as Int
                val mk = gate.withAuth {
                    wrap.unwrapDevice(
                        epoch,
                        e["alias"] as String,
                        Base64.decode(e["wrappedMkDevice"] as String, Base64.NO_WRAP),
                        pin,
                        MasterKeyWrap.KdfParams.parse(e["kdfParamsJson"] as String),
                    )
                }
                unwrapped.add(epoch to mk)
            }
        } catch (e: Exception) {
            unwrapped.forEach { it.second.fill(0) }
            throw e
        }
        // The highest epoch is the active one; older ones stay readable (§8.6).
        val active = unwrapped.maxOf { it.first }
        unwrapped.forEach { (epoch, mk) -> session.bindMasterKey(epoch, mk, active = epoch == active) }
        return null
    }

    private fun verifyPin(call: MethodCall): Boolean = try {
        val mk = gate.withAuth {
            wrap.unwrapDevice(
                epochFromAlias(call.string("alias")),
                call.string("alias"),
                call.bytes("wrappedMkDevice"),
                call.string("pin"),
                MasterKeyWrap.KdfParams.parse(call.string("kdfParamsJson")),
            )
        }
        mk.fill(0)
        true
    } catch (e: AuthFailedException) {
        false
    }

    private fun verifyRecovery(call: MethodCall): Boolean = try {
        wrap.unwrapRecovery(
            call.bytes("wrappedMkRecovery"),
            call.string("passphrase"),
            MasterKeyWrap.KdfParams.parse(call.string("kdfParamsJson")),
        ).fill(0)
        true
    } catch (e: AuthFailedException) {
        false
    }

    private fun changeRecovery(call: MethodCall): Map<String, Any?> {
        val mk = session.masterKeyCopy(call.int("epoch"))
        try {
            val params = MasterKeyWrap.KdfParams.parse(call.string("kdfParamsJson"))
                .withRecoverySalt(Primitives.randomBytes(16))
            return mapOf(
                "wrappedMkRecovery" to wrap.wrapRecovery(mk, call.string("newPassphrase"), params).b64(),
                "kdfParamsJson" to params.toJson(),
            )
        } finally {
            mk.fill(0)
        }
    }

    /** Bootstrap §9.9 step 3–4: recover MK from the passphrase, re-wrap for this device. */
    private fun importUnwrapped(call: MethodCall): Map<String, Any?> {
        if (!keystore.hasDeviceLock()) throw NoDeviceLockException()
        val epoch = call.int("epoch")
        val mk = wrap.unwrapRecovery(
            call.bytes("wrappedMkRecovery"),
            call.string("passphrase"),
            MasterKeyWrap.KdfParams.parse(call.string("kdfParamsJson")),
        )
        val wrapped = gate.withAuth { wrap.wrapNew(epoch, mk, call.string("pin"), call.string("passphrase")) }
        session.bindMasterKey(epoch, mk, active = true)
        return wrapped.toMap()
    }

    private fun epochFromAlias(alias: String): Int = alias.substringAfterLast('.').toInt()

    private fun MasterKeyWrap.Wrapped.toMap() = mapOf(
        "wrappedMkDevice" to device.b64(),
        "wrappedMkRecovery" to recovery.b64(),
        "kdfParamsJson" to params.toJson(),
        "alias" to alias,
        "strongbox" to strongBox,
    )
}

/** `dokki/vault_crypto` — see the Dart `NativeCryptoBridge` for the protocol. */
class CryptoChannel(private val session: KeySession) : WorkerChannel() {
    override fun handle(call: MethodCall): Any? = when (call.method) {
        "generateAndBind" -> {
            val (wrapped, keyId) = session.generateAndBind(call.int("epoch"), call.int("purpose"))
            mapOf("wrappedDek" to wrapped.b64(), "keyId" to keyId)
        }
        "bindWrappedDek" -> session.bindWrapped(call.bytes("wrappedDek"), call.int("epoch"), call.int("purpose"))
        "gcmEncrypt" -> mapOf(
            "ciphertext" to session.encryptChunk(
                call.int("keyId"), call.bytes("salt"), call.bytes("nonce"), call.bytes("aad"), call.bytes("plaintext"),
            ).b64(),
        )
        "gcmDecrypt" -> mapOf(
            "plaintext" to session.decryptChunk(
                call.int("keyId"), call.bytes("salt"), call.bytes("nonce"), call.bytes("aad"), call.bytes("ciphertext"),
            ).b64(),
        )
        "gcmHeaderEncrypt" -> mapOf(
            "tag" to session.sealHeader(call.int("keyId"), call.bytes("salt"), call.bytes("aad")).b64(),
        )
        "gcmHeaderDecrypt" -> {
            session.verifyHeader(call.int("keyId"), call.bytes("salt"), call.bytes("aad"), call.bytes("tag"))
            null
        }
        "releaseKey" -> { session.release(call.int("keyId")); null }
        else -> throw NotImplementedError()
    }
}

/**
 * `dokki/vault_imaging` — see the Dart `NativeImagingBridge` for the protocol.
 * Rasters (export bitmaps) live in [rasters] between calls and are dropped
 * on lock, since they are plaintext pixels.
 */
class ImagingChannel(session: KeySession) : WorkerChannel() {
    private val imaging = NativeImaging(session)
    private val rasters = HashMap<Int, NativeImaging.Raster>()
    private var nextRasterId = 1

    init {
        session.onLock { clearRasters() }
    }

    override fun handle(call: MethodCall): Any? = when (call.method) {
        "ping" -> true
        "inspect" -> inspect(call)
        "process" -> process(call)
        "prepareRaster" -> prepareRaster(call)
        "measureRaster" -> imaging.measure(raster(call), call.string("format"), call.int("quality"))
        "encodeRaster" -> encodeRaster(call)
        "downscaleRaster" -> register(imaging.downscale(raster(call), call.argument<Double>("factor")!!))
        "disposeRaster" -> { dispose(call.int("rasterId")); null }
        "detectDocument" -> detectDocument(call)
        else -> throw NotImplementedError()
    }

    /** §5.3: detection is separate from application — the quad it finds
     * becomes a `PerspectiveOp` in the recipe, so upgrading the detector
     * later never invalidates a stored recipe. */
    private fun detectDocument(call: MethodCall): Map<String, Any?> {
        val quad = imaging.detectQuad(
            File(call.string("inputPath")),
            call.int("purpose"),
        ) ?: return mapOf("found" to false)
        return mapOf(
            "found" to true,
            "quad" to mapOf(
                "p0" to mapOf("x" to quad[0].toDouble(), "y" to quad[1].toDouble()),
                "p1" to mapOf("x" to quad[2].toDouble(), "y" to quad[3].toDouble()),
                "p2" to mapOf("x" to quad[4].toDouble(), "y" to quad[5].toDouble()),
                "p3" to mapOf("x" to quad[6].toDouble(), "y" to quad[7].toDouble()),
            ),
        )
    }

    private fun inspect(call: MethodCall): Map<String, Any?> {
        val info = imaging.inspect(File(call.string("inputPath")), call.int("purpose"))
        return mapOf("width" to info.width, "height" to info.height, "mime" to info.mime)
    }

    private fun process(call: MethodCall): Map<String, Any?> {
        val processed = imaging.process(
            input = File(call.string("inputPath")),
            inputPurpose = call.int("purpose"),
            output = File(call.string("outputPath")),
            outputPurpose = call.int("outputPurpose"),
            epoch = call.int("epoch"),
            opsJson = call.string("opsJson"),
            decodeTargetPixels = call.long("decodeTargetPixels"),
            maxDecodedPixels = call.long("maxDecodedPixels"),
            maxEdge = call.argument<Int>("maxEdge") ?: 0,
            preferredMime = call.argument<String>("preferredMime"),
            quality = call.int("quality"),
        )
        val sealed = processed.sealed
        return mapOf(
            "width" to processed.width,
            "height" to processed.height,
            "mime" to processed.mime,
            "keyEpoch" to sealed.keyEpoch,
            "wrappedDek" to sealed.wrappedDek.b64(),
            "plaintextSize" to sealed.plaintextSize,
            "ciphertextSize" to sealed.ciphertextSize,
            "plaintextSha256" to sealed.plaintextSha256,
            "ciphertextSha256" to sealed.ciphertextSha256,
        )
    }

    private fun prepareRaster(call: MethodCall): Map<String, Any?> {
        val raster = imaging.prepareRaster(
            input = File(call.string("inputPath")),
            purpose = call.int("purpose"),
            width = call.argument<Int>("width"),
            height = call.argument<Int>("height"),
            fit = call.argument<String>("fit") ?: "contain",
            grayscale = call.argument<Boolean>("grayscale") ?: false,
            bw = call.argument<Boolean>("bw") ?: false,
            background = call.argument<Number>("background")?.toLong()?.toInt(),
            maxDecodedPixels = call.long("maxDecodedPixels"),
        )
        return register(raster)
    }

    private fun encodeRaster(call: MethodCall): Map<String, Any?> {
        val raster = raster(call)
        val bytes = imaging.encode(raster.bitmap, call.string("format"), call.int("quality"))
        return mapOf(
            "bytes" to bytes,
            "width" to raster.bitmap.width,
            "height" to raster.bitmap.height,
        )
    }

    @Synchronized
    private fun register(raster: NativeImaging.Raster): Map<String, Any?> {
        val id = nextRasterId++
        rasters[id] = raster
        return mapOf(
            "rasterId" to id,
            "width" to raster.bitmap.width,
            "height" to raster.bitmap.height,
            "sourceWidth" to raster.sourceWidth,
            "sourceHeight" to raster.sourceHeight,
        )
    }

    @Synchronized
    private fun raster(call: MethodCall): NativeImaging.Raster =
        rasters[call.int("rasterId")] ?: throw IllegalArgumentException("unknown raster")

    @Synchronized
    private fun dispose(id: Int) {
        rasters.remove(id)?.bitmap?.recycle()
    }

    @Synchronized
    fun clearRasters() {
        rasters.values.forEach { it.bitmap.recycle() }
        rasters.clear()
    }

    private fun MethodCall.long(key: String): Long = (argument<Number>(key)!!).toLong()
}
