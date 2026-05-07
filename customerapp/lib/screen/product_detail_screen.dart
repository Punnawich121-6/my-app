import 'package:flutter/material.dart';
import '../main.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> store;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductDetailScreen({
    super.key,
    required this.item,
    required this.store,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _qty;
  String _selectedSize = '14"';
  bool _isFav = false;

  static const _sizes = ['10"', '14"', '16"'];

  @override
  void initState() {
    super.initState();
    _qty = widget.qty > 0 ? widget.qty : 1;
  }

  double get _price => double.tryParse(widget.item['price'].toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final name = widget.item['name']?.toString() ?? '';
    final storeName = widget.store['name']?.toString() ?? '';
    final storeAddress = widget.store['address']?.toString() ?? '';
    final imageUrl = widget.item['image_url']?.toString();
    final rating = double.tryParse(widget.store['rating']?.toString() ?? '4.7') ?? 4.7;

    return Scaffold(
      backgroundColor: CColors.bg,
      body: Column(
        children: [
          // ── Hero image area ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero with back + heart buttons
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, st) => Container(
                                  color: CColors.orangeLight,
                                  child: const Center(
                                    child: Icon(Icons.fastfood_rounded,
                                        color: CColors.orange, size: 72),
                                  ),
                                ),
                              )
                            : Container(
                                color: CColors.orangeLight,
                                child: const Center(
                                  child: Icon(Icons.fastfood_rounded,
                                      color: CColors.orange, size: 72),
                                ),
                              ),
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                                      size: 15, color: CColors.text),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isFav = !_isFav),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: _isFav ? CColors.orange : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _isFav ? Colors.white : CColors.orange,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Product info ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: CColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: CColors.orange, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                storeAddress.isNotEmpty ? storeAddress : storeName,
                                style: const TextStyle(
                                    fontSize: 13, color: CColors.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rating row
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: CColors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CColors.text),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                  color: CColors.muted, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.delivery_dining_rounded,
                                color: CColors.orange, size: 16),
                            const SizedBox(width: 4),
                            const Text('Free',
                                style: TextStyle(
                                    fontSize: 13, color: CColors.text)),
                            const SizedBox(width: 16),
                            Container(
                              width: 4, height: 4,
                              decoration: const BoxDecoration(
                                  color: CColors.muted, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time_rounded,
                                color: CColors.orange, size: 16),
                            const SizedBox(width: 4),
                            const Text('20 min',
                                style: TextStyle(
                                    fontSize: 13, color: CColors.text)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          widget.item['description']?.toString().isNotEmpty == true
                              ? widget.item['description'].toString()
                              : 'A delicious dish made with the freshest ingredients, carefully prepared to bring you the best flavors and a satisfying meal experience.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CColors.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SIZE selector
                        const Text(
                          'SIZE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: CColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _sizes.map((size) {
                            final selected = size == _selectedSize;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                width: 60, height: 44,
                                decoration: BoxDecoration(
                                  color: selected ? CColors.orange : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: selected
                                        ? CColors.orange
                                        : const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    size,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : CColors.text,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // INGREDIENTS section
                        const Text(
                          'INGREDIENTS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: CColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(5, (i) {
                            const icons = [
                              Icons.grain_rounded,
                              Icons.eco_rounded,
                              Icons.local_pizza_rounded,
                              Icons.kebab_dining_rounded,
                              Icons.lunch_dining_rounded,
                            ];
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 52, height: 52,
                              decoration: const BoxDecoration(
                                color: CColors.orangeLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icons[i],
                                color: CColors.orange,
                                size: 24,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom bar ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Price',
                        style: TextStyle(fontSize: 12, color: CColors.muted)),
                    Text(
                      '\$${_price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Qty selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_qty > 1) {
                            setState(() => _qty--);
                            widget.onRemove();
                          }
                        },
                        child: const SizedBox(
                          width: 36, height: 36,
                          child: Center(
                            child: Icon(Icons.remove_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Center(
                          child: Text(
                            '$_qty',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _qty++);
                          widget.onAdd();
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                            color: CColors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Add to cart button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAdd();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
