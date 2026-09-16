/// Plugin registration entry point.
library;

class PlatformAndroidPlugin {
  PlatformAndroidPlugin();

  static void register() {
    // All channels are lazily created by the bridge classes; nothing to
    // register beyond the plugin itself.
  }
}
