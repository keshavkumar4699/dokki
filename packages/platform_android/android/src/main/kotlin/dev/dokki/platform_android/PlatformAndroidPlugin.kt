package dev.dokki.platform_android

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.provider.Settings
import android.os.Build
import android.view.WindowManager
import androidx.fragment.app.FragmentActivity
import dev.dokki.platform_android.keystore.KeySession
import dev.dokki.platform_android.keystore.KeystoreKek
import dev.dokki.platform_android.keystore.UserAuthGate
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android bridge for the dokki vault (ARCHITECTURE.md §3, `platform_android`).
 *
 * Contains no business logic. Channels:
 *  - `dokki/vault_security`  — FLAG_SECURE, device-lock probe, root signals.
 *  - `dokki/vault_keymanager` — Keystore-bound master key wrapping (§8).
 *  - `dokki/vault_crypto`     — per-chunk AES-GCM over session-held DEKs (§7.2).
 *  - `dokki/vault_imaging`    — the native image pipeline (§17 Phase 4):
 *    sealed file in, sealed file out, bitmaps only in native memory.
 */
class PlatformAndroidPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private lateinit var securityChannel: MethodChannel
    private lateinit var keyManagerChannel: MethodChannel
    private lateinit var cryptoChannel: MethodChannel
    private lateinit var imagingChannel: MethodChannel
    private var keyManagerHandler: KeyManagerChannel? = null
    private var cryptoHandler: CryptoChannel? = null
    private var imagingHandler: ImagingChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null

    // One session per engine: the master key lives here and nowhere else.
    private val session = KeySession()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        securityChannel = MethodChannel(binding.binaryMessenger, "dokki/vault_security")
        securityChannel.setMethodCallHandler(this)

        val keystore = KeystoreKek(binding.applicationContext)
        val gate = UserAuthGate { activity as? FragmentActivity }
        keyManagerHandler = KeyManagerChannel(session, keystore, gate)
        keyManagerChannel = MethodChannel(binding.binaryMessenger, "dokki/vault_keymanager")
        keyManagerChannel.setMethodCallHandler(keyManagerHandler)
        cryptoHandler = CryptoChannel(session)
        cryptoChannel = MethodChannel(binding.binaryMessenger, "dokki/vault_crypto")
        cryptoChannel.setMethodCallHandler(cryptoHandler)
        imagingHandler = ImagingChannel(session)
        imagingChannel = MethodChannel(binding.binaryMessenger, "dokki/vault_imaging")
        imagingChannel.setMethodCallHandler(imagingHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        securityChannel.setMethodCallHandler(null)
        keyManagerChannel.setMethodCallHandler(null)
        cryptoChannel.setMethodCallHandler(null)
        imagingChannel.setMethodCallHandler(null)
        keyManagerHandler?.shutdown()
        cryptoHandler?.shutdown()
        imagingHandler?.shutdown()
        session.lock()
        context = null
    }

    // ── ActivityAware ───────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // §8.5: applied ALWAYS, from the moment the activity exists, so no
        // screen can ever be captured before Dart gets a chance to ask.
        applySecureWindow()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        applySecureWindow()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ── dokki/vault_security ────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "applySecureWindow" -> {
                applySecureWindow()
                result.success(null)
            }
            "hasDeviceLock" -> result.success(hasDeviceLock())
            "rootSignals" -> result.success(rootSignals())
            "freeDiskSpace" -> result.success(freeDiskSpace())
            else -> result.notImplemented()
        }
    }

    private fun applySecureWindow() {
        val current = activity ?: return
        if (captureAllowedForDebugging(current)) return
        current.runOnUiThread {
            current.window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                current.setRecentsScreenshotEnabled(false)
            }
        }
    }

    /**
     * Debug builds only: `adb shell settings put global dokki_allow_capture 1`
     * lets screenshots through for UI review. Release builds ignore it.
     */
    private fun captureAllowedForDebugging(current: Activity): Boolean {
        val debuggable = (current.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) return false
        return Settings.Global.getInt(current.contentResolver, "dokki_allow_capture", 0) == 1
    }

    /** §7.6: free bytes on the vault's filesystem, for the storage budget. */
    private fun freeDiskSpace(): Long {
        val dir = context?.filesDir ?: return -1L
        return android.os.StatFs(dir.absolutePath).availableBytes
    }

    /** §8.3: auth-bound Keystore keys need a secure lock screen. */
    private fun hasDeviceLock(): Boolean {
        val keyguard = context?.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        return keyguard?.isDeviceSecure ?: false
    }

    /** Advisory only (§8.7 T4): the app warns, it does not refuse. */
    private fun rootSignals(): List<String> {
        val signals = mutableListOf<String>()
        val suPaths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/system/app/Superuser.apk", "/data/local/xbin/su",
        )
        if (suPaths.any { java.io.File(it).exists() }) signals.add("SU_BINARY")
        if (Build.TAGS?.contains("test-keys") == true) signals.add("TEST_KEYS")
        val fingerprint = Build.FINGERPRINT.lowercase()
        if (fingerprint.contains("generic") || fingerprint.contains("emulator") ||
            Build.MODEL.contains("Emulator") || Build.MODEL.contains("Android SDK built for")
        ) {
            signals.add("EMULATOR")
        }
        return signals
    }
}
