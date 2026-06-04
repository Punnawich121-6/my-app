import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'api_service.dart';

class OrderAlertService {
  static final instance = OrderAlertService._();
  OrderAlertService._();

  static String get _audioUrl => '${ApiService.serverBase}/public/audio/new_order.mp3';
  static const _repeatSec = 6;

  final _player = AudioPlayer();
  Timer? _timer;
  int    _pendingCount = 0;
  bool   _playing = false;

  int get pendingCount => _pendingCount;

  /// เรียกทุกครั้งที่รู้จำนวน pending orders (จาก dashboard poll หรือ socket)
  void syncWithPendingCount(int count) {
    _pendingCount = count;
    if (count > 0) {
      _ensureAlertRunning();
    } else {
      _stop();
    }
  }

  void _ensureAlertRunning() {
    _playOnce();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) {
      if (_pendingCount > 0) {
        _playOnce();
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _pendingCount = 0;
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

  Future<void> prefetch() async {}
}
