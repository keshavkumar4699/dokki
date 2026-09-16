/// Public export surface of `vault_imaging`: the Dart reference image
/// processor, the reference raster engine for exports, and the
/// plaintext-source seam the composition root adapts.
library;

export 'src/dart_processor/dart_decode.dart';
export 'src/dart_processor/dart_image_processor.dart';
export 'src/dart_processor/dart_raster_engine.dart';
export 'src/error_boundary.dart' show ImagingException;
export 'src/plaintext_source.dart';
