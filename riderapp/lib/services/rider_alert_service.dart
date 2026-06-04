import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'audio_web.dart';

class RiderAlertService {
  static final instance = RiderAlertService._();
  RiderAlertService._();

  static const _repeatSec = 6;

  final _orderPlayer   = AudioPlayer();
  final _paymentPlayer = AudioPlayer();
  Timer? _timer;
  int  _prevCount  = -1;
  bool _playing    = false;

  void syncWithOrderCount(int count) {
    final isNew = _prevCount >= 0 && count > _prevCount;
    _prevCount = count;

    if (isNew) {
      _startAlert();
    } else if (count == 0) {
      _stop();
    }
  }

  void _startAlert() {
    _playOnce();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) {
      if (_prevCount > 0) {
        _playOnce();
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _orderPlayer.stop().catchError((_) {});
    _playing = false;
  }

  Future<void> _playOnce() async {
    if (_playing) return;
    _playing = true;
    try {
      if (kIsWeb) {
        await playWebAudio('assets/audio/rider-order.mp3');
      } else {
        await _orderPlayer.play(AssetSource('audio/rider-order.mp3'));
      }
    } catch (_) {
      // ignore
    } finally {
      _playing = false;
    }
  }

  Future<void> playPaymentSound() async {
    try {
      if (kIsWeb) {
        await playWebAudio('assets/audio/sound-payment.mp3');
      } else {
        await _paymentPlayer.play(AssetSource('audio/sound-payment.mp3'));
      }
    } catch (_) {}
  }

  void onOrderAccepted() {
    _stop();
    _prevCount = -1;
  }
}
