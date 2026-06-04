import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class OrderAlertService {
  static final instance = OrderAlertService._();
  OrderAlertService._();

  // ─── ตั้งค่า Botnoi ──────────────────────────────────────────────────────────
  static const _botnoiApiKey = 'YOUR_BOTNOI_TOKEN_HERE'; // ← ใส่ token Botnoi
  static const _alertText    = 'มีออเดอร์ใหม่เข้ามา';
  static const _speaker      = '1';   // 1 = ผู้หญิง TH, 2 = ผู้ชาย TH
  static const _repeatSec    = 6;     // พูดซ้ำทุกกี่วินาที

  // ─── State ───────────────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  Timer?  _timer;
  int     _pendingCount = 0;
  String? _audioUrl;        // cache URL จาก Botnoi
  bool    _fetching = false;
  bool    _playing  = false;

  int get pendingCount => _pendingCount;

  // ─── เรียกเมื่อ new_order socket มา ──────────────────────────────────────────
  Future<void> onNewOrder() async {
    _pendingCount++;
    await _startAlert();
  }

  // ─── เรียกเมื่อ merchant เปิดหน้า orders (ถือว่าเห็นแล้ว) ───────────────────
  void dismiss() {
    _pendingCount = 0;
    _timer?.cancel();
    _timer = null;
    _player.stop();
    _playing = false;
  }

  // ─── Internal ────────────────────────────────────────────────────────────────
  Future<void> _startAlert() async {
    await _playOnce();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) async {
      if (_pendingCount > 0) {
        await _playOnce();
      } else {
        dismiss();
      }
    });
  }

  Future<void> _playOnce() async {
    if (_playing) return;
    final url = await _getAudioUrl();
    if (url == null) return;
    try {
      _playing = true;
      await _player.play(UrlSource(url));
      _player.onPlayerComplete.first.then((_) => _playing = false);
    } catch (_) {
      _playing = false;
    }
  }

  Future<String?> _getAudioUrl() async {
    if (_audioUrl != null) return _audioUrl;
    if (_fetching) return null;
    if (_botnoiApiKey == 'YOUR_BOTNOI_TOKEN_HERE') return null;
    _fetching = true;
    try {
      final res = await http.post(
        Uri.parse('https://api-voice.botnoi.ai/openapi/v1/generate_audio'),
        headers: {
          'Authorization': 'Bearer $_botnoiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text':       _alertText,
          'speaker':    _speaker,
          'volume':     1,
          'speed':      1,
          'type_media': 'mp3',
          'save_file':  true,
          'language':   'th',
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _audioUrl = (data['audio_url'] ?? data['url'] ?? data['media_url']) as String?;
      }
    } catch (_) {}
    _fetching = false;
    return _audioUrl;
  }

  // pre-fetch ตอน app start เพื่อให้เสียงพร้อมทันที
  Future<void> prefetch() => _getAudioUrl();
}
