import 'package:flutter/material.dart';
import '../main.dart';

class NavigationScreen extends StatelessWidget {
  final String storeAddress;
  final String storeName;
  final String customerAddress;
  final String customerName;

  const NavigationScreen({
    super.key,
    required this.storeAddress,
    required this.storeName,
    required this.customerAddress,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.bg,
      appBar: AppBar(
        backgroundColor: RiderColors.bg,
        elevation: 0,
        title: const Text('เส้นทางการส่ง', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: RiderColors.text)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: RiderColors.text),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Map placeholder
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Grid lines to simulate map
                  CustomPaint(size: const Size(double.infinity, 220), painter: _MapGridPainter()),
                  // Route line
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: RiderColors.blue, borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.directions_bike_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('กำลังนำทาง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)]),
                          child: const Text('แผนที่จะแสดงเมื่อเชื่อมต่อ GPS', style: TextStyle(fontSize: 12, color: RiderColors.muted)),
                        ),
                      ],
                    ),
                  ),
                  // Distance badge
                  Positioned(
                    right: 12, bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)]),
                      child: const Column(children: [
                        Text('~3.2 km', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: RiderColors.text)),
                        Text('~12 นาที', style: TextStyle(fontSize: 11, color: RiderColors.muted)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: RiderColors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // Pickup point
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: RiderColors.blueLight, shape: BoxShape.circle),
                          child: const Icon(Icons.store_rounded, color: RiderColors.blue, size: 18),
                        ),
                        Container(width: 2, height: 50, color: RiderColors.blueLight),
                      ]),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('จุดรับอาหาร', style: TextStyle(fontSize: 12, color: RiderColors.muted)),
                        const SizedBox(height: 2),
                        Text(storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
                        const SizedBox(height: 2),
                        Text(storeAddress, style: const TextStyle(fontSize: 13, color: RiderColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                    ],
                  ),

                  // Dropoff point
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, color: RiderColors.blue, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('จุดส่งอาหาร', style: TextStyle(fontSize: 12, color: RiderColors.muted)),
                        const SizedBox(height: 2),
                        Text(customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RiderColors.text)),
                        const SizedBox(height: 2),
                        Text(customerAddress, style: const TextStyle(fontSize: 13, color: RiderColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info row
            Row(children: [
              Expanded(child: _InfoCard(icon: Icons.route_rounded, label: 'ระยะทาง', value: '3.2 km')),
              const SizedBox(width: 12),
              Expanded(child: _InfoCard(icon: Icons.access_time_rounded, label: 'เวลาโดยประมาณ', value: '12 นาที')),
              const SizedBox(width: 12),
              Expanded(child: _InfoCard(icon: Icons.local_gas_station_rounded, label: 'ค่าน้ำมัน', value: '~฿15')),
            ]),
            const SizedBox(height: 20),

            // Open map apps button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.map_rounded),
                label: const Text('เปิดใน Google Maps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RiderColors.blue),
                  foregroundColor: RiderColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('เปิดใน Apple Maps', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Icon(icon, color: RiderColors.blue, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: RiderColors.text)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: RiderColors.muted), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB2DFDB).withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Draw a simple route
    final routePaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..lineTo(size.width * 0.8, size.height * 0.7);
    canvas.drawPath(path, routePaint);
    // Start dot
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 6, Paint()..color = const Color(0xFFF5A623));
    // End dot
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 6, Paint()..color = const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
