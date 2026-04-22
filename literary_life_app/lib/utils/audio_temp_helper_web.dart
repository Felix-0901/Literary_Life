import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// On the web the MediaRecorder produces a WebM/Opus blob.
const String recordingUploadFilename = 'voice.webm';

/// On the web the `record` package ignores the path argument and instead
/// emits a `blob:` URL from `stop()`. We still return a hint filename so
/// the recorder has something to hand back to the browser.
Future<String> buildRecordingTarget() async {
  return 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
}

/// Fetch the blob URL into memory so it can be uploaded as bytes.
Future<Uint8List> readRecordingBytes(String blobUrl) async {
  final response = await http.get(Uri.parse(blobUrl));
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return response.bodyBytes;
  }
  throw StateError('無法讀取錄音 blob：HTTP ${response.statusCode}');
}

/// Nothing to clean up on the web — once the blob URL has no references
/// the browser garbage-collects it automatically.
Future<void> deleteRecording(String blobUrl) async {}
