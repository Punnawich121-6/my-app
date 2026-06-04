import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'audio_web.dart';

class OrderAlertService {
  static final instance = OrderAlertService._();
  OrderAlertService._();

  static const _repeatSec = 6;

  final _player = AudioPlayer();
  Timer? _timer;
  int  _pendingCount = 0;
  int  _prevCount    = -1;
  bool _playing      = false;

  int get pendingCount => _pendingCount;

  void syncWithPendingCount(int count) {
    final isNewOrder = _prevCount >= 0 && count > _prevCount;
    _prevCount    = count;
    _pendingCount = count;

    if (count == 0) {
      _stop();
    } else if (isNewOrder) {
      _startAlert();
    }
  }

  void onOrderAccepted() {
    _stop();
    _prevCount = (_pendingCount - 1).clamp(0, _pendingCount);
    _pendingCount = _prevCount;
  }

  void _startAlert() {
    _playOnce();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: _repeatSec), (_) {
      if (_pendingCount > 0 && _timer != null) {
        _playOnce();
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer        = null;
    _pendingCount = 0;
    _player.stop().catchError((_) {});
    _playing      = false;
  }

  Future<void> _playOnce() async {
    if (_playing) return;
    _playing = true;
    try {
      if (kIsWeb) {
        await playWebAudio('assets/audio/new_order.mp3');
      } else {
        await _player.play(AssetSource('audio/new_order.mp3'));
      }
    } catch (_) {
      // ignore
    } finally {
      _playing = false;
    }
  }

  Future<void> prefetch() async {}
}
