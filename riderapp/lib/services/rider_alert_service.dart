import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

class RiderAlertService {
  static final instance = RiderAlertService._();
  RiderAlertService._();

  final _orderPlayer   = AudioPlayer();
  final _paymentPlayer = AudioPlayer();

  int  _prevCount = -1;
  bool _alertOn   = false;

  Future<void> _initOrderPlayer() async {
    await _orderPlayer.setReleaseMode(ReleaseMode.loop);
    await _orderPlayer.setVolume(1.0);
  }

  /// เรียกทุกครั้งหลัง poll
  void syncWithOrderCount(int count) {
    final isNew = _prevCount >= 0 && count > _prevCount;
    _prevCount  = count;

    if (isNew) {
      _alertCount = count;
      _startAlert();
    } else if (count == 0) {
      _stopAlert();
    } else {
      _alertCount = count;
    }
  }

  Future<void> _startAlert() async {
    if (_alertOn) return;
    _alertOn = true;
    try {
      await _initOrderPlayer();
      if (kIsWeb) {
        // BytesSource หลีกเลี่ยงปัญหา service worker 206 range request
        final data = await rootBundle.load('assets/audio/rider-order.mp3');
        await _orderPlayer.play(BytesSource(data.buffer.asUint8List()));
      } else {
        await _orderPlayer.play(AssetSource('audio/rider-order.mp3'));
      }
    } catch (_) {
      _alertOn = false;
    }
  }

  void _stopAlert() {
    _alertCount = 0;
    _alertOn    = false;
    _orderPlayer.stop().catchError((_) {});
  }

  /// เรียกเมื่อ rider รับงาน → หยุดทันที
  void onOrderAccepted() {
    _stopAlert();
    _prevCount = -1;
  }

  /// เล่นเสียงเมื่อส่งสำเร็จ (เล่นครั้งเดียว)
  Future<void> playPaymentSound() async {
    try {
      await _paymentPlayer.setReleaseMode(ReleaseMode.release);
      if (kIsWeb) {
        final data = await rootBundle.load('assets/audio/sound-payment.mp3');
        await _paymentPlayer.play(BytesSource(data.buffer.asUint8List()));
      } else {
        await _paymentPlayer.play(AssetSource('audio/sound-payment.mp3'));
      }
    } catch (_) {}
  }
}
