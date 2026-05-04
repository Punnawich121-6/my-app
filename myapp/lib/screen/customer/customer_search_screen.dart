import 'package:flutter/material.dart';
import 'customer_filter_bottom_sheet.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Pizza');

  final List<String> _recentKeywords = ['Burger', 'Sandwich', 'Pizza', 'Sanwich'];

  final List<Map<String, dynamic>> _suggestedRestaurants = [
    {
      'name': 'Pansi Restaurant',
      'rating': '4.7',
      'image': 'https://images.unsplash.com/photo-1544025162-811114bd2f27?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'American Spicy Burger Shop',
      'rating': '4.3',
      'image': 'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=200&auto=format&fit=crop',
    },
    {
      'name': 'Cafenio Coffee Club',
      'rating': '4.0',
      'image': 'https://images.unsplash.com/photo-1600891964092-4316c288032e?q=80&w=200&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> _popularFastFood = [
    {
      'name': 'European Pizza',
      'restaurant': 'Uttora Coffe House',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Buffalo Pizza',
      'restaurant': 'Cafenio Coffee Club',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=300&auto=format&fit=crop',
    },
  ];

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0), // Scaled 1.5x
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 36),
                _buildSearchBar(),
                const SizedBox(height: 36),
                const Text(
                  'Recent Keywords',
                  style: TextStyle(
                    fontSize: 27, // Scaled 1.5x
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF323643),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRecentKeywords(),
                const SizedBox(height: 36),
                const Text(
                  'Suggested Restaurants',
                  style: TextStyle(
                    fontSize: 27, // Scaled 1.5x
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF323643),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSuggestedRestaurants(),
                const SizedBox(height: 36),
                const Text(
                  'Popular Fast Food',
                  style: TextStyle(
                    fontSize: 27, // Scaled 1.5x
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF323643),
                  ),
                ),
                const SizedBox(height: 24),
                _buildPopularFastFood(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            const SizedBox(width: 24),
            const Text(
              'Search',
              style: TextStyle(
                fontSize: 27, // Scaled 1.5x
                color: Color(0xFF323643),
              ),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1D1D),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 36, // Scaled 1.5x
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFFE724C),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 22, color: Color(0xFF323643)),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(
            color: Color(0xFF8A8E9B),
            fontSize: 22,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8E9B), size: 36),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Color(0xFFD3D1D8), size: 30),
                onPressed: () {
                  _searchController.clear();
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFFFE724C), size: 30),
                onPressed: _showFilterSheet, // Added filter button here
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        ),
      ),
    );
  }

  Widget _buildRecentKeywords() {
    return Wrap(
      spacing: 15, // horizontal spacing
      runSpacing: 15, // vertical spacing
      children: _recentKeywords.map((keyword) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEBEBEB)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            keyword,
            style: const TextStyle(
              fontSize: 21, // Scaled 1.5x
              color: Color(0xFF323643),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestedRestaurants() {
    return Column(
      children: _suggestedRestaurants.map((restaurant) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF6F6F6), width: 1.5)),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  restaurant['image'],
                  width: 90, // Scaled 1.5x (60 * 1.5)
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant['name'],
                      style: const TextStyle(
                        fontSize: 24, // Scaled 1.5x (16 * 1.5)
                        color: Color(0xFF323643),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFE724C), size: 24),
                        const SizedBox(width: 6),
                        Text(
                          restaurant['rating'],
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323643),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPopularFastFood() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _popularFastFood.map((food) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: food == _popularFastFood.first ? 15 : 0,
              left: food == _popularFastFood.last ? 15 : 0,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipOval(
                  child: Image.network(
                    food['image'],
                    width: 150, // Scaled 1.5x
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  food['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21, // Scaled 1.5x
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF323643),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  food['restaurant'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8A8E9B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
