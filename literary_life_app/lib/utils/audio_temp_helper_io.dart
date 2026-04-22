import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Suggested filename (and extension) for uploads.
const String recordingUploadFilename = 'voice.m4a';

/// Returns a real temp-directory path where the recorder can write.
Future<String> buildRecordingTarget() async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
}

/// Reads the finished recording into memory.
Future<Uint8List> readRecordingBytes(String path) async {
  return File(path).readAsBytes();
}

/// Best-effort delete of the temporary recording.
Future<void> deleteRecording(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Swallow — the file may already be gone.
  }
}
