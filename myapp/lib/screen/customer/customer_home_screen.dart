import 'package:flutter/material.dart';
import '../../main.dart'; // For AppColors and AppTextStyles
import 'customer_search_screen.dart';
import 'customer_restaurant_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': '🔥', 'type': 'emoji'},
    {'name': 'Hot Dog', 'icon': '🌭', 'type': 'emoji'},
    {'name': 'Burger', 'icon': '🍔', 'type': 'emoji'},
    {'name': 'Pizza', 'icon': '🍕', 'type': 'emoji'},
  ];

  final List<Map<String, dynamic>> _restaurants = [
    {
      'name': 'Rose Garden Restaurant',
      'tags': 'Burger - Chicken - Rice - Wings',
      'rating': '4.7',
      'deliveryFee': 'Free',
      'time': '20 min',
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Green Bowl Healthy',
      'tags': 'Salad - Vegan - Healthy',
      'rating': '4.9',
      'deliveryFee': '\$2.00',
      'time': '15 min',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Using solid white as per design
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0), // Scaled 1.5x
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 36), // Scaled 1.5x
                _buildGreeting(),
                const SizedBox(height: 30), // Scaled 1.5x
                _buildSearchBar(),
                const SizedBox(height: 36), // Scaled 1.5x
                _buildCategoriesHeader(),
                const SizedBox(height: 24), // Scaled 1.5x
                _buildCategoriesList(),
                const SizedBox(height: 48), // Scaled 1.5x
                _buildRestaurantsHeader(),
                const SizedBox(height: 24), // Scaled 1.5x
                _buildRestaurantsList(),
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
        // Menu Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 36, // Scaled 1.5x
            icon: const Icon(Icons.sort, color: Color(0xFF1E1D1D)),
            onPressed: () {},
          ),
        ),
        // Location Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'DELIVER TO',
              style: TextStyle(
                color: Color(0xFFFE724C),
                fontSize: 18, // Scaled 1.5x
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: const [
                Text(
                  'Halal Lab office',
                  style: TextStyle(
                    color: Color(0xFF323643),
                    fontSize: 21, // Scaled 1.5x
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Color(0xFF323643), size: 30), // Scaled 1.5x
              ],
            ),
          ],
        ),
        // Cart Button
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
                padding: const EdgeInsets.all(7), // Scaled 1.5x
                decoration: const BoxDecoration(
                  color: Color(0xFFFE724C),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15, // Scaled 1.5x
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

  Widget _buildGreeting() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          color: Color(0xFF323643),
          fontSize: 42, // Scaled 1.5x
        ),
        children: [
          TextSpan(text: 'Hey Halal, '),
          TextSpan(
            text: 'Good Afternoon!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(24), // Scaled 1.5x
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerSearchScreen()),
          );
        },
        style: const TextStyle(fontSize: 22), // Add scaled font size for input
        decoration: InputDecoration(
          hintText: 'Search dishes, restaurants',
          hintStyle: const TextStyle(
            color: Color(0xFF8A8E9B),
            fontSize: 22, // Scaled 1.5x
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8E9B), size: 36), // Scaled 1.5x
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24), // Scaled 1.5x
        ),
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'All Categories',
          style: TextStyle(
            color: Color(0xFF323643),
            fontSize: 30, // Scaled 1.5x
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: const [
            Text(
              'See All',
              style: TextStyle(
                color: Color(0xFF8A8E9B),
                fontSize: 21, // Scaled 1.5x
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF8A8E9B), size: 27), // Scaled 1.5x
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 82, // Scaled 1.5x
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final category = _categories[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 24), // Scaled 1.5x
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Scaled 1.5x
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFE724C).withOpacity(0.5) : Colors.white,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD580), Color(0xFFFFB347)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(45), // Scaled 1.5x
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFE724C).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 7), // Scaled 1.5x
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 7), // Scaled 1.5x
                        )
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54, // Scaled 1.5x
                    height: 54, // Scaled 1.5x
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category['icon'],
                      style: const TextStyle(fontSize: 30), // Scaled 1.5x
                    ),
                  ),
                  const SizedBox(width: 15), // Scaled 1.5x
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.black : const Color(0xFF323643),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 21, // Scaled 1.5x
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Open Restaurants',
          style: TextStyle(
            color: Color(0xFF323643),
            fontSize: 30, // Scaled 1.5x
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: const [
            Text(
              'See All',
              style: TextStyle(
                color: Color(0xFF8A8E9B),
                fontSize: 21, // Scaled 1.5x
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF8A8E9B), size: 27), // Scaled 1.5x
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerRestaurantScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 36), // Scaled 1.5x
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24), // Scaled 1.5x
                child: Image.network(
                  restaurant['imageUrl'],
                  height: 270, // Scaled 1.5x
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 270, // Scaled 1.5x
                      width: double.infinity,
                      color: const Color(0xFFF6F6F6),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFE724C),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18), // Scaled 1.5x
              Text(
                restaurant['name'],
                style: const TextStyle(
                  color: Color(0xFF323643),
                  fontSize: 30, // Scaled 1.5x
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6), // Scaled 1.5x
              Text(
                restaurant['tags'],
                style: const TextStyle(
                  color: Color(0xFF8A8E9B),
                  fontSize: 21, // Scaled 1.5x
                ),
              ),
              const SizedBox(height: 18), // Scaled 1.5x
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFE724C), size: 27), // Scaled 1.5x
                      const SizedBox(width: 6), // Scaled 1.5x
                      Text(
                        restaurant['rating'],
                        style: const TextStyle(
                          color: Color(0xFF323643),
                          fontWeight: FontWeight.bold,
                          fontSize: 21, // Scaled 1.5x
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36), // Scaled 1.5x
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Color(0xFFFE724C), size: 27), // Scaled 1.5x
                      const SizedBox(width: 6), // Scaled 1.5x
                      Text(
                        restaurant['deliveryFee'],
                        style: const TextStyle(
                          color: Color(0xFF323643),
                          fontSize: 21, // Scaled 1.5x
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36), // Scaled 1.5x
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFFE724C), size: 27), // Scaled 1.5x
                      const SizedBox(width: 6), // Scaled 1.5x
                      Text(
                        restaurant['time'],
                        style: const TextStyle(
                          color: Color(0xFF323643),
                          fontSize: 21, // Scaled 1.5x
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
