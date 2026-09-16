/// The vault lock state.
library;

enum LockState {
  /// No key material in memory; the vault cannot be read.
  locked,

  /// Key material is being negotiated (unlock in progress).
  unlocking,

  /// The master key session is live; reads/writes are possible.
  unlocked,
}
