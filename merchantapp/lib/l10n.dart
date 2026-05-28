import 'app_settings.dart';

/// Returns [th] in Thai mode, [en] in English mode.
String t(String th, String en) => AppSettings.instance.isEnglish ? en : th;
