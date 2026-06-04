// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart';

Future<void> playWebAudio(String assetKey) async {
  try {
    final data = await rootBundle.load(assetKey);
    final blob = html.Blob([data.buffer.asUint8List()], 'audio/mpeg');
    final url = html.Url.createObjectUrl(blob);
    final audio = html.AudioElement(url);
    audio.play().catchError((_) => null);
    audio.onEnded.listen((_) => html.Url.revokeObjectUrl(url));
  } catch (_) {}
}
