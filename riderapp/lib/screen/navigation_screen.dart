import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

const _kBangkok = LatLng(13.7563, 100.5018);
const _kAvgSpeedKmh = 25.0; // avg city speed for ETA


class NavigationScreen extends StatefulWidget {
  final String storeAddress;
  final String storeName;
  final String customerAddress;
  final String customerName;
  final double? customerLat;
  final double? customerLng;

  const NavigationScreen({
    super.key,
    required this.storeAddress,
    required this.storeName,
    required this.customerAddress,
    required this.customerName,
    this.customerLat,
    this.customerLng,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();

  LatLng? _myLoc;
  LatLng? _storeLoc;
  LatLng? _custLoc;
  List<LatLng> _route = [];
  double? _distKm;
  int? _durMin;
  bool _loading = true;

  bool _navMode = false;
  bool _userPanned = false;
  StreamSubscription<Position>? _locSub;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    final my = await _getPosition() ?? _kBangkok;
    final storeLoc = await _geocode(widget.storeAddress);
    final store = storeLoc ?? LatLng(_kBangkok.latitude + 0.005, _kBangkok.longitude);

    final LatLng cust;
    if (widget.customerLat != null && widget.customerLng != null) {
      cust = LatLng(widget.customerLat!, widget.customerLng!);
    } else {
      cust = await _geocode(widget.customerAddress) ??
          LatLng(_kBangkok.latitude - 0.005, _kBangkok.longitude + 0.01);
    }
    final routeData = await _fetchRoute([my, store, cust]);

    if (!mounted) return;
    setState(() {
      _myLoc    = my;
      _storeLoc = store;
      _custLoc  = cust;
      _route    = routeData?.points ?? [my, store, cust];
      _distKm   = routeData?.dist;
      _durMin   = routeData?.dur;
      _loading  = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitAll();
    });
  }

  // ── Navigation mode ───────────────────────────────────────────────────────────
  void _startNavMode() {
    if (_myLoc == null) return;
    setState(() {
      _navMode    = true;
      _userPanned = false;
    });
    _mapController.move(_myLoc!, 17);

    _locSub?.cancel();
    _locSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _myLoc = loc);
      if (_navMode && !_userPanned) {
        _mapController.move(loc, _mapController.camera.zoom);
      }
      _updateRemainingDistance();
    });
  }

  void _stopNavMode() {
    _locSub?.cancel();
    _locSub = null;
    setState(() => _navMode = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitAll();
    });
  }

  void _recenter() {
    if (_myLoc == null) return;
    setState(() => _userPanned = false);
    _mapController.move(_myLoc!, 17);
  }

  // ── ETA helpers ───────────────────────────────────────────────────────────────
  int _etaFromDist(double? km) =>
      km != null ? (km / _kAvgSpeedKmh * 60).ceil() : 0;

  String _etaText(double? km) {
    final min = _etaFromDist(km);
    if (min <= 0) return '< 1 นาที';
    if (min < 60) return '$min นาที';
    return '${min ~/ 60} ชม. ${min % 60} นาที';
  }

  // ── Distance to store (straight-line) ────────────────────────────────────────
  double? _distToStoreKm() {
    if (_myLoc == null || _storeLoc == null) return null;
    return Geolocator.distanceBetween(
          _myLoc!.latitude, _myLoc!.longitude,
          _storeLoc!.latitude, _storeLoc!.longitude,
        ) /
        1000;
  }

  // ── Network helpers ───────────────────────────────────────────────────────────
  Future<void> _updateRemainingDistance() async {
    if (_myLoc == null) return;
    final target = _storeLoc;
    if (target == null) return;
    final data = await _fetchRoute([_myLoc!, target]);
    if (!mounted || data == null) return;
    setState(() {
      _distKm = data.dist;
      _durMin = data.dur;
    });
  }

  Future<LatLng?> _getPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> _geocode(String address) async {
    if (address.isEmpty) return null;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'th',
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

  Future<({List<LatLng> points, double dist, int dur})?> _fetchRoute(
      List<LatLng> pts) async {
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
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
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

  void _fitAll() {
    final pts = [_myLoc, _storeLoc, _custLoc].whereType<LatLng>().toList();
    if (pts.length < 2) return;
    final bounds = LatLngBounds.fromPoints(pts);
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.fromLTRB(40, 120, 40, 300),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _myLoc ?? _kBangkok,
            initialZoom: 13,
            onMapEvent: (event) {
              if (_navMode &&
                  event is MapEventMove &&
                  event.source != MapEventSource.mapController) {
                setState(() => _userPanned = true);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.riderapp',
            ),
            if (_route.length >= 2)
              PolylineLayer(polylines: [
                Polyline(
                  points: _route,
                  strokeWidth: _navMode ? 7 : 5,
                  color: RiderColors.blue,
                ),
              ]),
            MarkerLayer(markers: [
              if (_myLoc != null) _buildRiderMarker(_myLoc!),
              if (_storeLoc != null)
                _buildMarker(_storeLoc!, Icons.store_rounded, Colors.white, RiderColors.blue),
              if (_custLoc != null)
                _buildMarker(_custLoc!, Icons.location_on_rounded,
                    Colors.white, RiderColors.red),
            ]),
          ],
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _navMode ? _buildNavTopBar() : _buildOverviewTopBar(),
          ),
        ),

        // Recenter button
        if (_navMode && _userPanned)
          Positioned(
            right: 16,
            bottom: 260,
            child: _CircleBtn(
              onTap: _recenter,
              child: Icon(Icons.my_location_rounded,
                  size: 22, color: RiderColors.blue),
            ),
          ),

        // Bottom panel
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _navMode ? _buildNavPanel() : _buildOverviewPanel(),
        ),
      ]),
    );
  }

  // ── Overview top bar ──────────────────────────────────────────────────────────
  Widget _buildOverviewTopBar() => Row(children: [
        _CircleBtn(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: RiderColors.text),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
              ],
            ),
            child: Row(children: [
              Icon(Icons.navigation_rounded, size: 15, color: RiderColors.blue),
              const SizedBox(width: 6),
              const Text('เส้นทางการส่ง',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: RiderColors.text)),
              if (_loading) ...[
                const Spacer(),
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: RiderColors.blue),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(width: 8),
        _CircleBtn(
          onTap: _fitAll,
          child: Icon(Icons.my_location_rounded, size: 18, color: RiderColors.blue),
        ),
      ]);

  // ── Nav top bar ───────────────────────────────────────────────────────────────
  Widget _buildNavTopBar() {
    const stepColor = RiderColors.blue;
    const stepText  = 'กำลังนำทาง';
    return Row(children: [
      _CircleBtn(
        onTap: _stopNavMode,
        child: const Icon(Icons.close_rounded, size: 18, color: RiderColors.text),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: stepColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: stepColor.withValues(alpha: 0.4), blurRadius: 12)
            ],
          ),
          child: Row(children: [
            const Icon(Icons.navigation_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(stepText,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white)),
            const Spacer(),
            if (_distKm != null)
              Text(
                '${_distKm!.toStringAsFixed(1)} กม.',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ]),
        ),
      ),
    ]);
  }

  // ── Status card (shared) ──────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    final distStore = _distToStoreKm();
    final etaStore  = _etaText(distStore);
    final etaCust   = _etaText(_distKm);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5), width: 1.5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Step progress bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            _StepDot(
              icon: Icons.store_rounded,
              label: 'รับอาหาร',
              active: true,
              done: false,
              color: RiderColors.blue,
            ),
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: RiderColors.blue.withValues(alpha: 0.2),
                ),
              ),
            ),
            _StepDot(
              icon: Icons.directions_bike_rounded,
              label: 'กำลังส่ง',
              active: false,
              done: false,
              color: const Color(0xFFFF8F00),
            ),
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                color: const Color(0xFFE0E0E0),
              ),
            ),
            _StepDot(
              icon: Icons.location_on_rounded,
              label: 'ส่งแล้ว',
              active: false,
              done: false,
              color: RiderColors.red,
            ),
          ]),
        ),

        const Divider(height: 1, color: Color(0xFFEEF1F5)),

        // ── ETA info row ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            _StatusBadge(
              icon: Icons.store_rounded,
              label: 'ถึงร้านใน',
              value: etaStore,
              color: RiderColors.blue,
            ),
            const SizedBox(width: 8),
            _StatusBadge(
              icon: Icons.location_on_rounded,
              label: 'ถึงลูกค้าใน',
              value: etaCust,
              color: RiderColors.red,
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Overview bottom panel ─────────────────────────────────────────────────────
  Widget _buildOverviewPanel() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Stats
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _StatChip(
                  icon: Icons.route_rounded,
                  label: _distKm != null
                      ? '${_distKm!.toStringAsFixed(1)} กม.'
                      : '—',
                  sub: 'ระยะทาง',
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.access_time_rounded,
                  label: _durMin != null ? '$_durMin นาที' : '—',
                  sub: 'โดยประมาณ',
                ),
              ]),
            ),
          const SizedBox(height: 12),

          // Status card
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatusCard(),
            ),
          const SizedBox(height: 12),

          // Waypoints
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
          const SizedBox(height: 14),

          // Start nav button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _startNavMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderColors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: RiderColors.blueLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text('เริ่มนำทาง',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      );

  // ── Nav bottom panel ──────────────────────────────────────────────────────────
  Widget _buildNavPanel() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Status card
            _buildStatusCard(),
            const SizedBox(height: 12),

            // Distance + ETA stats
            Row(children: [
              Expanded(
                child: _NavStat(
                  icon: Icons.route_rounded,
                  value: _distKm != null
                      ? '${_distKm!.toStringAsFixed(1)}'
                      : '—',
                  unit: 'กม. เหลืออยู่',
                  color: RiderColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NavStat(
                  icon: Icons.access_time_rounded,
                  value: _etaText(_distKm),
                  unit: 'โดยประมาณ',
                  color: const Color(0xFFFF8F00),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Stop button
            SizedBox(
              width: double.infinity, height: 44,
              child: OutlinedButton.icon(
                onPressed: _stopNavMode,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  foregroundColor: RiderColors.muted,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('หยุดนำทาง',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
      );

  // ── Markers ───────────────────────────────────────────────────────────────────
  Marker _buildRiderMarker(LatLng point) => Marker(
        point: point,
        width: 56, height: 56,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            if (_navMode)
              Container(
                width: 56 * (0.7 + _pulseCtrl.value * 0.3),
                height: 56 * (0.7 + _pulseCtrl.value * 0.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RiderColors.blue
                      .withValues(alpha: 0.2 * (1 - _pulseCtrl.value)),
                ),
              ),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: RiderColors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: RiderColors.blue.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.directions_bike_rounded,
                  color: Colors.white, size: 22),
            ),
          ]),
        ),
      );

  Marker _buildMarker(
          LatLng point, IconData icon, Color iconColor, Color bgColor) =>
      Marker(
        point: point,
        width: 44, height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      );
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool done;
  final Color color;
  const _StepDot({
    required this.icon,
    required this.label,
    required this.active,
    required this.done,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 40 : 34,
          height: active ? 40 : 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active
                ? color
                : color.withValues(alpha: 0.12),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
                : null,
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            color: done || active ? Colors.white : color,
            size: active ? 20 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: done || active ? color : RiderColors.muted,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400)),
      ]);
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        flex: wide ? 2 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ]),
            ),
          ]),
        ),
      );
}

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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
            ],
          ),
          child: child,
        ),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _StatChip(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: RiderColors.blueLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(icon, color: RiderColors.blue, size: 20),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: RiderColors.text)),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 10, color: RiderColors.muted)),
            ]),
          ]),
        ),
      );
}

class _NavStat extends StatelessWidget {
  final IconData icon;
  final String value, unit;
  final Color color;
  const _NavStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 10, color: RiderColors.muted)),
            ]),
          ),
        ]),
      );
}

class _WaypointRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tag, name, address;
  final bool showLine;
  const _WaypointRow({
    required this.icon,
    required this.color,
    required this.tag,
    required this.name,
    required this.address,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          if (showLine)
            Container(width: 2, height: 40, color: color.withValues(alpha: 0.2)),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showLine ? 0 : 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tag,
                  style: const TextStyle(fontSize: 11, color: RiderColors.muted)),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RiderColors.text)),
              const SizedBox(height: 2),
              Text(address,
                  style: const TextStyle(fontSize: 12, color: RiderColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ]);
}
