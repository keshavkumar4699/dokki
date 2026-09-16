package dev.dokki.dokki

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FragmentActivity flavour so `platform_android` can show the
 * BiometricPrompt (device credential / biometric) that gates the
 * auth-bound Keystore key (ARCHITECTURE.md §8.3).
 */
class MainActivity : FlutterFragmentActivity()
