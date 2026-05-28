import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../main.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapCtrl = MapController();
  late LatLng _center;
  String _address = 'กำลังระบุที่อยู่...';
  bool _geocoding = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? const LatLng(13.7563, 100.5018);
    _reverseGeocode(_center);
    if (widget.initial == null) _tryGetCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _tryGetCurrentLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(ll, 16);
      setState(() => _center = ll);
      _reverseGeocode(ll);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng ll) async {
    if (!mounted) return;
    setState(() { _geocoding = true; _address = 'กำลังระบุที่อยู่...'; });
    try {
      final res = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json'
          '&lat=${ll.latitude}&lon=${ll.longitude}&accept-language=th',
        ),
        headers: {'User-Agent': 'CustomerApp/1.0'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _address = data['display_name'] as String? ??
              '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _geocoding = false;
        });
      } else {
        setState(() {
          _address = '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _geocoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _geocoding = false;
        });
      }
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove ||
        event is MapEventScrollWheelZoom ||
        event is MapEventFlingAnimation) {
      final center = _mapCtrl.camera.center;
      if (center != _center) {
        setState(() => _center = center);
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 700),
          () => _reverseGeocode(center),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 15,
            onMapEvent: _onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.customerapp',
            ),
          ],
        ),

        // Center pin — tip at screen center
        Center(
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: CColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: CColors.orange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                ),
                Container(width: 3, height: 12, color: CColors.orange),
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: CColors.orange, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),

        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                ),
                child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1A1A1A), size: 26),
              ),
            ),
          ),
        ),

        // Title
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: const Text('เลื่อนแผนที่เพื่อเลือกที่อยู่',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
              ),
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          right: 16,
          bottom: 160,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF1A1A1A), size: 24),
                  ),
                ),
                GestureDetector(
                  onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
                  child: const SizedBox(
                    width: 48, height: 48,
                    child: Icon(Icons.remove_rounded, color: Color(0xFF1A1A1A), size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom confirm panel
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ที่อยู่จัดส่ง',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CColors.muted)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_rounded, color: CColors.orange, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _geocoding
                          ? const Text('กำลังระบุที่อยู่...',
                              style: TextStyle(fontSize: 14, color: CColors.muted))
                          : Text(_address,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                              maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _geocoding
                        ? null
                        : () => Navigator.pop(context, {
                              'lat': _center.latitude,
                              'lng': _center.longitude,
                              'address': _address,
                            }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: CColors.orangeMid,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ยืนยันที่อยู่นี้',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
