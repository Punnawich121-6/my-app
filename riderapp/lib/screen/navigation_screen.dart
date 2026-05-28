import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

const _kBangkok = LatLng(13.7563, 100.5018);
const _kAvgSpeedKmh = 25.0;

class NavigationScreen extends StatefulWidget {
  final String storeAddress;
  final String storeName;
  final String customerAddress;
  final String customerName;
  final double? customerLat;
  final double? customerLng;
  final String? riderPhotoUrl;
  final String riderName;

  const NavigationScreen({
    super.key,
    required this.storeAddress,
    required this.storeName,
    required this.customerAddress,
    required this.customerName,
    this.customerLat,
    this.customerLng,
    this.riderPhotoUrl,
    this.riderName = '',
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final _mapController = MapController();

  LatLng? _storeLoc;
  LatLng? _custLoc;
  List<LatLng> _route = [];
  double? _distKm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storeLoc = await _geocode(widget.storeAddress);
    final store = storeLoc ?? LatLng(_kBangkok.latitude + 0.005, _kBangkok.longitude);

    final LatLng cust;
    if (widget.customerLat != null && widget.customerLng != null) {
      cust = LatLng(widget.customerLat!, widget.customerLng!);
    } else {
      cust = await _geocode(widget.customerAddress) ??
          LatLng(_kBangkok.latitude - 0.005, _kBangkok.longitude + 0.01);
    }

    final routeData = await _fetchRoute([store, cust]);

    if (!mounted) return;
    setState(() {
      _storeLoc = store;
      _custLoc  = cust;
      _route   = routeData?.points ?? [store, cust];
      _distKm  = routeData?.dist;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitAll();
    });
  }

  void _fitAll() {
    final pts = [_storeLoc, _custLoc].whereType<LatLng>().toList();
    if (pts.length < 2) return;
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(pts),
      padding: const EdgeInsets.fromLTRB(40, 120, 40, 300),
    ));
  }

  void _goToMyLocation() {
    if (_route.isNotEmpty) {
      _mapController.move(_route[0], 19);
    }
  }

  String _etaText(double? km) {
    if (km == null) return '—';
    final min = (km / _kAvgSpeedKmh * 60).ceil();
    if (min <= 0) return '< 1 นาที';
    if (min < 60) return '$min นาที';
    return '${min ~/ 60} ชม. ${min % 60} นาที';
  }

  Future<LatLng?> _geocode(String address) async {
    if (address.isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address, 'format': 'json', 'limit': '1', 'countrycodes': 'th',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'ZestAndSavory/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      return LatLng(double.parse(list[0]['lat']), double.parse(list[0]['lon']));
    } catch (_) {
      return null;
    }
  }

  Future<({List<LatLng> points, double dist, int dur})?> _fetchRoute(List<LatLng> pts) async {
    try {
      final coords = pts.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data['code'] != 'Ok') return null;
      final r = data['routes'][0];
      final polyline = (r['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return (
        points: polyline,
        dist: (r['distance'] as num).toDouble() / 1000,
        dur: ((r['duration'] as num).toDouble() / 60).round(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _kBangkok,
            initialZoom: 13,
            maxZoom: 50,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.riderapp',
              maxNativeZoom: 19,
              maxZoom: 50,
            ),
            if (_route.length >= 2)
              PolylineLayer(polylines: [
                Polyline(points: _route, strokeWidth: 5, color: RiderColors.blue),
              ]),
            MarkerLayer(markers: [
              if (_route.isNotEmpty) _buildRiderMarker(_route[0]),
              if (_custLoc != null)
                _buildMarker(_custLoc!, Icons.location_on_rounded, Colors.white, RiderColors.red),
            ]),
          ],
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _CircleBtn(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: RiderColors.text),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Row(children: [
                    const Icon(Icons.navigation_rounded, size: 15, color: RiderColors.blue),
                    const SizedBox(width: 6),
                    const Text('เส้นทางการส่ง',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: RiderColors.text)),
                    if (_loading) ...[
                      const Spacer(),
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: RiderColors.blue),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // Crosshair + Zoom controls
        Positioned(
          right: 16,
          top: 130,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleBtn(
                onTap: _goToMyLocation,
                child: const Icon(Icons.my_location_rounded, size: 20, color: RiderColors.blue),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _mapController.move(
                          _mapController.camera.center, (_mapController.camera.zoom + 1).clamp(1.0, 50.0)),
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                        ),
                        child: const Icon(Icons.add_rounded, color: RiderColors.text, size: 22),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _mapController.move(
                          _mapController.camera.center, _mapController.camera.zoom - 1),
                      child: const SizedBox(
                        width: 44, height: 44,
                        child: Icon(Icons.remove_rounded, color: RiderColors.text, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom panel
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildPanel(),
        ),
      ]),
    );
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x);
  }

  Marker _buildRiderMarker(LatLng point) {
    double angle = 0;
    if (_route.length >= 2) {
      angle = _bearingBetween(_route[0], _route[1]);
    }
    return Marker(
      point: point,
      width: 48, height: 48,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          decoration: BoxDecoration(
            color: RiderColors.blue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildPanel() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
      ),

      if (!_loading)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _StatChip(
              icon: Icons.route_rounded,
              label: _distKm != null ? '${_distKm!.toStringAsFixed(1)} กม.' : '—',
              sub: 'ระยะทาง',
            ),
            const SizedBox(width: 10),
            _StatChip(
              icon: Icons.access_time_rounded,
              label: _etaText(_distKm),
              sub: 'โดยประมาณ',
            ),
          ]),
        ),
      const SizedBox(height: 12),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _WaypointRow(
          icon: Icons.store_rounded,
          color: RiderColors.blue,
          tag: 'จุดรับอาหาร',
          name: widget.storeName,
          address: widget.storeAddress,
          showLine: true,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _WaypointRow(
          icon: Icons.location_on_rounded,
          color: RiderColors.red,
          tag: 'จุดส่งอาหาร',
          name: widget.customerName,
          address: widget.customerAddress,
          showLine: false,
        ),
      ),

      Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              foregroundColor: RiderColors.muted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('ปิดแผนที่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    ]),
  );

  Marker _buildMarker(LatLng point, IconData icon, Color iconColor, Color bgColor) =>
      Marker(
        point: point,
        width: 44, height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      );
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: child,
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _StatChip({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0CC), width: 1.5),
      ),
      child: Row(children: [
        Icon(icon, color: RiderColors.blue, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: RiderColors.text)),
          Text(sub, style: const TextStyle(fontSize: 12, color: RiderColors.muted)),
        ]),
      ]),
    ),
  );
}

class _WaypointRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag, name, address;
  final bool showLine;
  const _WaypointRow({
    required this.icon, required this.color,
    required this.tag, required this.name,
    required this.address, required this.showLine,
  });

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      if (showLine) Container(width: 2, height: 40, color: color.withValues(alpha: 0.2)),
    ]),
    const SizedBox(width: 14),
    Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: showLine ? 0 : 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tag, style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
          const SizedBox(height: 2),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RiderColors.text)),
          const SizedBox(height: 2),
          Text(address,
              style: const TextStyle(fontSize: 12, color: RiderColors.muted),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    ),
  ]);
}
