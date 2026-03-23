import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiService.createProductReview(
        widget.product['_id'],
        _rating,
        _commentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!')),
        );
        _commentController.clear();
        setState(() => _rating = 5);
        // Normally we would refetch the product details here
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.product['reviews'] as List<dynamic>? ?? [];
    final avgRating = widget.product['rating']?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(avgRating),
                  const SizedBox(height: 32),
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  if (reviews.isEmpty)
                    const Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey))
                  else
                    ...reviews.map((r) => _buildReviewItem(r)),
                  const SizedBox(height: 32),
                  _buildAddReviewSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF2D6C50),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${widget.product['_id']}',
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: widget.product['imageUrl'] != null && widget.product['imageUrl'].toString().isNotEmpty
                ? (widget.product['imageUrl'].toString().startsWith('assets/')
                    ? Image.asset(widget.product['imageUrl'], fit: BoxFit.contain)
                    : Image.network(widget.product['imageUrl'], fit: BoxFit.contain))
                : const Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(double avgRating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Badge(
              label: Text(widget.product['category'] ?? 'Category'),
              backgroundColor: const Color(0xFFE8F5E9),
              textColor: const Color(0xFF2D6C50),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  ' (${widget.product['numReviews'] ?? 0})',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.product['name'],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.product['price']} XOF / ${widget.product['unit']}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D6C50)),
        ),
        const SizedBox(height: 20),
        const Text(
          'Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product['description'] ?? 'No description available.',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildReviewItem(dynamic review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 14,
                    color: index < review['rating'] ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'], style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D6C50).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  Icons.star,
                  color: index < _rating ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              hintStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6C50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
extension LineHeight on TextStyle {
  TextStyle get lineHeight => copyWith(height: 1.5);
}
