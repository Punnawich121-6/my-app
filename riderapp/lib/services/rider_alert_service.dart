import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class RiderAlertService {
  static final instance = RiderAlertService._();
  RiderAlertService._();

  static const _repeatSec = 6;

  final _orderPlayer   = AudioPlayer();
  final _paymentPlayer = AudioPlayer();
  Timer? _timer;
  int    _prevCount  = -1;
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
    _playOrderSound();
    _timer ??= Timer.periodic(const Duration(seconds: _repeatSec), (_) {
      if (_alertCount > 0) {
        _playOrderSound();
      } else {
        _stop();
      }
    });
  }

  void _stop() {
    _alertCount = 0;
    _timer?.cancel();
    _timer = null;
    _orderPlayer.stop();
    _playing = false;
  }

  Future<void> _playOrderSound() async {
    if (_playing) return;
    _playing = true;
    try {
      await _orderPlayer.play(AssetSource('audio/rider-order.mp3'));
    } catch (_) {
      // ignore
    } finally {
      _playing = false;
    }
  }

  /// เล่นเสียงเมื่อส่งสำเร็จ
  Future<void> playPaymentSound() async {
    try {
      await _paymentPlayer.stop();
      await _paymentPlayer.play(AssetSource('audio/sound-payment.mp3'));
    } catch (_) {}
  }

  /// เรียกเมื่อ rider รับงาน → หยุดเสียงทั้งหมดทันที ไม่สนใจ order อื่นที่เหลือ
  void onOrderAccepted() {
    _stop();
    _prevCount = -1; // reset ให้ poll ครั้งถัดไปไม่ trigger เสียงใหม่
  }
}
