import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class OrderAlertService {
  static final instance = OrderAlertService._();
  OrderAlertService._();

  static const _asset      = 'audio/new_order.mp3';
  static const _repeatSec  = 6;

  final _player = AudioPlayer();
  Timer? _timer;
  int    _pendingCount = 0;
  bool   _playing = false;

  int get pendingCount => _pendingCount;

  Future<void> onNewOrder() async {
    _pendingCount++;
    await _playOnce();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) async {
      if (_pendingCount > 0) {
        await _playOnce();
      } else {
        dismiss();
      }
    });
  }

  void dismiss() {
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
      await _player.play(AssetSource(_asset));
      _player.onPlayerComplete.first.then((_) => _playing = false);
    } catch (_) {
      _playing = false;
    }
  }

  // ไม่ต้องใช้แล้ว แต่เก็บไว้ให้ main screen เรียกได้โดยไม่ error
  Future<void> prefetch() async {}
}
