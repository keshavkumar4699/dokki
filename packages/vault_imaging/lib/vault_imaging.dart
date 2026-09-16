/// Public export surface of `vault_imaging`: the native pipeline
/// (`NativeImageProcessor`, `NativeRasterEngine` over the Kotlin bridge),
/// the Dart reference implementations used as fallback and test oracle,
/// and the seams the composition root adapts.
library;

export 'src/dart_processor/dart_decode.dart';
export 'src/dart_processor/dart_image_processor.dart';
export 'src/dart_processor/dart_raster_engine.dart';
export 'src/error_boundary.dart' show ImagingException;
export 'src/native/edge_detector_impl.dart';
export 'src/native/native_image_processor.dart';
export 'src/native/native_raster_engine.dart';
export 'src/native/sealed_files.dart';
export 'src/plaintext_source.dart';
