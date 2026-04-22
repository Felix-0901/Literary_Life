/// Cross-platform helpers for managing the temporary audio blob/file
/// produced by the `record` package.
///
/// On iOS / Android / desktop the package writes to a real file on disk
/// (`dart:io` path). On Flutter Web the package exposes a browser blob
/// URL (`blob:https://...`). The helpers below hide that difference so
/// the UI layer can stay platform-agnostic.
library;

export 'audio_temp_helper_io.dart'
    if (dart.library.html) 'audio_temp_helper_web.dart';
