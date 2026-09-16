/// Camera / gallery capture, adapted to the application layer's
/// `ImportSource`. The picked file is streamed straight into the sealed
/// blob store; no `Uint8List` of the whole image is ever held here.
library;

import 'package:image_picker/image_picker.dart';
import 'package:vault_app_core/vault_app_core.dart';

enum CaptureSource { camera, gallery }

final class ImageSourcePicker {
  ImageSourcePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns `null` when the user backs out of the picker.
  Future<ImportSource?> pick(CaptureSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        CaptureSource.camera => ImageSource.camera,
        CaptureSource.gallery => ImageSource.gallery,
      },
      // The image processor bakes EXIF orientation; keep the original
      // pixels — no picker-side re-encode that would alter the bytes.
      requestFullMetadata: false,
    );
    return file == null ? null : await toImportSource(file);
  }

  /// Several at once (document pages).
  Future<List<ImportSource>> pickMany() async {
    final files = await _picker.pickMultiImage(requestFullMetadata: false);
    return [for (final file in files) await toImportSource(file)];
  }

  static Future<ImportSource> toImportSource(XFile file) async => ImportSource(
    open: file.openRead,
    byteSize: await file.length(),
    mimeHint: file.mimeType,
    displayName: _titleFrom(file.name),
  );

  /// `IMG_20260916_101530.jpg` → `IMG_20260916_101530`; a camera capture
  /// has no meaningful name, so it becomes no title at all.
  static String? _titleFrom(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    // Camera captures and picker cache files (`IMG_2026…`, `33`,
    // `image_picker_abc`) carry no meaning; only a name with real words
    // is worth suggesting.
    final generic = RegExp(
      '^(IMG|PXL|DSC|DCIM|Screenshot|image_picker|scaled)',
      caseSensitive: false,
    );
    if (base.length < 3 ||
        !RegExp('[A-Za-z]{3,}').hasMatch(base) ||
        generic.hasMatch(base)) {
      return null;
    }
    return base.replaceAll(RegExp('[_-]+'), ' ');
  }
}
