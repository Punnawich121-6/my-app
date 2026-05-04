import 'package:flutter/material.dart';
import 'payment_screen.dart';

class CustomerRestaurantScreen extends StatefulWidget {
  const CustomerRestaurantScreen({super.key});

  @override
  State<CustomerRestaurantScreen> createState() => _CustomerRestaurantScreenState();
}

class _CustomerRestaurantScreenState extends State<CustomerRestaurantScreen> {
  String _selectedCategory = 'Burger';
  final Map<int, int> _cart = {}; // index -> quantity

  double get _total => _menuItems.asMap().entries
      .where((e) => (_cart[e.key] ?? 0) > 0)
      .fold(0.0, (sum, e) {
        final price = double.tryParse(
          (e.value['price'] as String).replaceAll('\$', ''),
        ) ?? 0;
        return sum + price * (_cart[e.key] ?? 0);
      });

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  final List<String> _categories = ['Burger', 'Sandwich', 'Pizza', 'Sanwich'];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'name': 'Burger Ferguson',
      'restaurant': 'Spicy Restaurant',
      'price': '\$40',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=300&auto=format&fit=crop', // Burger 1
    },
    {
      'name': 'Rockin\' Burgers',
      'restaurant': 'Cafecafachino', // The image text says this, maybe a mistake in design but I'll follow it
      'price': '\$40',
      'image': 'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=300&auto=format&fit=crop', // Burger 2
    },
    {
      'name': 'Bacon Egg Burger',
      'restaurant': 'Spicy Restaurant',
      'price': '\$45',
      'image': 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?q=80&w=300&auto=format&fit=crop', // Burger 3
    },
    {
      'name': 'Classic Cheese',
      'restaurant': 'Spicy Restaurant',
      'price': '\$35',
      'image': 'https://images.unsplash.com/photo-1594212202675-7b5c65529f5f?q=80&w=300&auto=format&fit=crop', // Burger 4
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _totalItems > 0 ? _buildCheckoutBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 36),
                _buildHeroImage(),
                const SizedBox(height: 36),
                _buildRestaurantInfo(),
                const SizedBox(height: 36),
                _buildCategoryTabs(),
                const SizedBox(height: 48),
                _buildMenuSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentScreen(total: _total)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFE724C),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                child: Text('$_totalItems', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F6F6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 30, // Scaled 1.5x
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1D1D)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Text(
          'Restaurant View',
          style: TextStyle(
            fontSize: 27, // Scaled 1.5x
            color: Color(0xFF323643),
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F6F6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 36, // Scaled 1.5x
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1E1D1D)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30), // Scaled 1.5x
      child: Image.network(
        'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?q=80&w=800&auto=format&fit=crop', // Chef plating food
        width: double.infinity,
        height: 250, // Scaled 1.5x
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spicy Restaurant',
          style: TextStyle(
            fontSize: 33, // Scaled 1.5x
            fontWeight: FontWeight.bold,
            color: Color(0xFF323643),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Maecenas sed diam eget risus varius blandit sit\namet non magna. Integer posuere erat a ante\nvenenatis dapibus posuere velit aliquet.',
          style: TextStyle(
            fontSize: 21, // Scaled 1.5x
            color: Color(0xFF8A8E9B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Row(
              children: const [
                Icon(Icons.star, color: Color(0xFFFE724C), size: 27),
                SizedBox(width: 6),
                Text(
                  '4.7',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF323643),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 36),
            Row(
              children: const [
                Icon(Icons.local_shipping_outlined, color: Color(0xFFFE724C), size: 27),
                SizedBox(width: 6),
                Text(
                  'Free',
                  style: TextStyle(
                    fontSize: 21,
                    color: Color(0xFF323643),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 36),
            Row(
              children: const [
                Icon(Icons.access_time, color: Color(0xFFFE724C), size: 27),
                SizedBox(width: 6),
                Text(
                  '20 min',
                  style: TextStyle(
                    fontSize: 21,
                    color: Color(0xFF323643),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 15), // Scaled 1.5x
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFE724C) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFE724C) : const Color(0xFFEBEBEB),
                ),
                borderRadius: BorderRadius.circular(45),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 21, // Scaled 1.5x
                  color: isSelected ? Colors.white : const Color(0xFF323643),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedCategory (10)',
          style: const TextStyle(
            fontSize: 30, // Scaled 1.5x
            fontWeight: FontWeight.bold,
            color: Color(0xFF323643),
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 24, // Scaled 1.5x
            mainAxisSpacing: 24,
            childAspectRatio: 0.75, // Adjust to fit content nicely
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The image is placed high up, clipping out of the box in the design
                        // To achieve this, we can use an Align or Transform
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Center(
                            child: ClipOval(
                              child: Image.network(
                                item['image'],
                                width: 120, // Scaled 1.5x
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Adjust spacing because image moved up
                        const SizedBox(height: -15),
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323643),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['restaurant'],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8A8E9B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          item['price'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323643),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _cart[index] = (_cart[index] ?? 0) + 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFE724C),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: (_cart[index] ?? 0) > 0
                            ? Text(
                                '${_cart[index]}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                              )
                            : const Icon(Icons.add, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
