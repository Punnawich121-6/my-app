import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../config.dart';

class RiderAlertService {
  static final instance = RiderAlertService._();
  RiderAlertService._();

  static String get _audioUrl => '$kBackendUrl/public/audio/rider-order.mp3';
  static const _repeatSec = 6;

  final _player = AudioPlayer();
  Timer? _timer;
  int    _prevCount  = -1; // -1 = ยังไม่เคย load
  int    _alertCount = 0;
  bool   _playing    = false;

  /// เรียกทุกครั้งหลัง poll — ตรวจว่ามี order ใหม่เข้าหรือเปล่า
  void syncWithOrderCount(int count) {
    final isNew = _prevCount >= 0 && count > _prevCount;
    _prevCount = count;

    if (isNew) {
      _alertCount = count;
      _ensureAlertRunning();
    } else if (count == 0) {
      _stop();
    } else {
      _alertCount = count;
    }
  }

  void _ensureAlertRunning() {
    _playOnce();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) {
      if (_alertCount > 0) {
        _playOnce();
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _alertCount = 0;
    _timer?.cancel();
    _timer = null;
    _player.stop();
    _playing = false;
  }

  Future<void> _playOnce() async {
    if (_playing) return;
    try {
      _playing = true;
      await _player.play(UrlSource(_audioUrl));
      _player.onPlayerComplete.first.then((_) => _playing = false);
    } catch (_) {
      _playing = false;
    }
  }

  /// เรียกเมื่อ rider รับงาน → ลด count ทันที
  void onOrderAccepted() {
    final newCount = (_alertCount - 1).clamp(0, _alertCount);
    _alertCount = newCount;
    if (newCount == 0) _stop();
  }
}
