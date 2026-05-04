import 'package:flutter/material.dart';

class CustomerFilterBottomSheet extends StatefulWidget {
  const CustomerFilterBottomSheet({super.key});

  @override
  State<CustomerFilterBottomSheet> createState() => _CustomerFilterBottomSheetState();
}

class _CustomerFilterBottomSheetState extends State<CustomerFilterBottomSheet> {
  // State for selections
  String _selectedDeliveryTime = '10-15 min';
  String _selectedPricing = '\$\$';
  int _selectedRating = 4; // 4 stars selected in the image

  final List<String> _offers = [
    'Delivery',
    'Pick Up',
    'Offer',
    'Online payment available'
  ];

  final List<String> _deliveryTimes = [
    '10-15 min',
    '20 min',
    '30 min'
  ];

  final List<String> _pricing = ['\$', '\$\$', '\$\$\$'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36), // Scaled 1.5x
          topRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(36.0), // Scaled 1.5x
          child: Column(
            mainAxisSize: MainAxisSize.min, // To wrap content in bottom sheet
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 36),
              _buildSectionTitle('OFFERS'),
              const SizedBox(height: 24),
              _buildOffers(),
              const SizedBox(height: 36),
              _buildSectionTitle('DELIVER TIME'),
              const SizedBox(height: 24),
              _buildDeliveryTime(),
              const SizedBox(height: 36),
              _buildSectionTitle('PRICING'),
              const SizedBox(height: 24),
              _buildPricing(),
              const SizedBox(height: 36),
              _buildSectionTitle('RATING'),
              const SizedBox(height: 24),
              _buildRating(),
              const SizedBox(height: 48),
              _buildFilterButton(),
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
        const Text(
          'Filter your search',
          style: TextStyle(
            fontSize: 27, // Scaled 1.5x
            fontWeight: FontWeight.w600,
            color: Color(0xFF323643),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F6F6),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 30, // Scaled 1.5x
            icon: const Icon(Icons.close, color: Color(0xFF323643)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21, // Scaled 1.5x
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8E9B), // Light grey text for section headers
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildOffers() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: _offers.map((offer) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEBEBEB)),
            borderRadius: BorderRadius.circular(45),
          ),
          child: Text(
            offer,
            style: const TextStyle(
              fontSize: 21,
              color: Color(0xFF5E616F), // Slightly lighter than pure black
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryTime() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _deliveryTimes.map((time) {
        final isSelected = time == _selectedDeliveryTime;
        return GestureDetector(
          onTap: () => setState(() => _selectedDeliveryTime = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFE724C) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFFFE724C) : const Color(0xFFEBEBEB),
              ),
              borderRadius: BorderRadius.circular(45),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 21,
                color: isSelected ? Colors.white : const Color(0xFF5E616F),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricing() {
    return Row(
      children: _pricing.map((price) {
        final isSelected = price == _selectedPricing;
        return GestureDetector(
          onTap: () => setState(() => _selectedPricing = price),
          child: Container(
            width: 75, // Scaled 1.5x (50 -> 75)
            height: 75,
            margin: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFE724C) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFFE724C) : const Color(0xFFEBEBEB),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              price,
              style: TextStyle(
                fontSize: 24,
                color: isSelected ? Colors.white : const Color(0xFF5E616F),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= _selectedRating;
        return GestureDetector(
          onTap: () => setState(() => _selectedRating = starNumber),
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBEBEB)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star,
              size: 36,
              color: isSelected ? const Color(0xFFFE724C) : const Color(0xFFD3D1D8), // Light grey for unselected
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFilterButton() {
    return SizedBox(
      width: double.infinity,
      height: 80, // Scaled 1.5x
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE724C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'FILTER',
          style: TextStyle(
            fontSize: 24, // Scaled 1.5x
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
