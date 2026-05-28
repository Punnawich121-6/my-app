import 'package:flutter/material.dart';
import '../../main.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CColors.bg,
      appBar: AppBar(
        backgroundColor: CColors.bg,
        elevation: 0,
        title: Text(widget.item['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: CColors.text)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: CColors.text),
          ),
        ),
      ),
      body: const Center(child: Text('Product Detail')),
    );
  }
}
