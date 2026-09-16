/// Clipboard with a fuse (§8.5): anything we put on the clipboard is
/// cleared after 30 seconds, so a copied value does not outlive its need.
library;

import 'dart:async';

import 'package:flutter/services.dart';

Timer? _pending;

/// Copies [text] to the system clipboard and schedules a clear in
/// [clearAfter] (default 30 s, §8.5). A second copy resets the fuse.
Future<void> copyWithTimeout(
  String text, {
  Duration clearAfter = const Duration(seconds: 30),
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  _pending?.cancel();
  _pending = Timer(clearAfter, () async {
    // Clear only if the clipboard still holds what we put there; the user
    // may have copied something else in the meantime.
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == text) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  });
}
