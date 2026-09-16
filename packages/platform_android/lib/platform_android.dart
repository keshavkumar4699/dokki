/// Android native bridge for the dokki vault.
///
/// This package contains ZERO Dart business logic: thin method-channel
/// wrappers over Kotlin implementations of the Keystore, Tink streaming
/// AEAD, Argon2id, the image pipeline, and platform security flags.
///
/// Security rule (§8.2): no key ever crosses the method channel. Kotlin
/// holds the master key in a native-side session; Dart only ever sees
/// opaque key ids and wrapped (encrypted) key material.
library;

export 'src/native_crypto.dart';
export 'src/native_errors.dart';
export 'src/native_imaging.dart';
export 'src/native_key_manager.dart';
export 'src/platform_android.dart';
export 'src/security.dart';
