import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PetShopScreen extends StatefulWidget {
  const PetShopScreen({super.key});

  @override
  State<PetShopScreen> createState() => _PetShopScreenState();
}

class _PetShopScreenState extends State<PetShopScreen> {
  String _selectedCategory = 'All';

  final _products = const [
    _Product('Food', 'Pro Plan Adult Dog Food', '₹2,499', Icons.restaurant, 'https://www.amazon.in/s?k=Purina+Pro+Plan+dog+food', 'https://www.flipkart.com/search?q=Purina+Pro+Plan+dog+food'),
    _Product('Grooming', 'Slicker Brush & Comb Set', '₹699', Icons.brush, 'https://www.amazon.in/s?k=dog+grooming+brush+set', 'https://www.flipkart.com/search?q=dog+grooming+brush+set'),
    _Product('Dental Care', 'Daily Dental Chews', '₹549', Icons.sentiment_satisfied, 'https://www.amazon.in/s?k=dog+dental+chews', 'https://www.flipkart.com/search?q=dog+dental+chews'),
    _Product('Supplements', 'Omega Skin & Coat Bites', '₹899', Icons.spa, 'https://www.amazon.in/s?k=dog+omega+supplement', 'https://www.flipkart.com/search?q=dog+omega+supplement'),
    _Product('Accessories', 'Reflective Walking Harness', '₹1,199', Icons.pets, 'https://www.amazon.in/s?k=reflective+dog+harness', 'https://www.flipkart.com/search?q=reflective+dog+harness'),
  ];

  Future<void> _openMarketplace(String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open marketplace')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Food', 'Grooming', 'Dental Care', 'Supplements', 'Accessories'];
    final visibleProducts = _selectedCategory == 'All'
        ? _products
        : _products.where((product) => product.category == _selectedCategory).toList();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pet Shop', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Trusted essentials for Milo and every stage of pet care.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: category == _selectedCategory,
                          onSelected: (_) => setState(() => _selectedCategory = category),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 850 ? 3 : constraints.maxWidth > 520 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleProducts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 1.5 : 0.78,
                        ),
                        itemBuilder: (context, index) => _ProductCard(product: visibleProducts[index], onOpen: _openMarketplace),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Product {
  final String category;
  final String name;
  final String price;
  final IconData icon;
  final String amazonUrl;
  final String flipkartUrl;

  const _Product(this.category, this.name, this.price, this.icon, this.amazonUrl, this.flipkartUrl);
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final Future<void> Function(String url) onOpen;

  const _ProductCard({required this.product, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(product.icon, size: 64, color: primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(product.category.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(product.price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => onOpen(product.amazonUrl), child: const Text('Amazon'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => onOpen(product.flipkartUrl), child: const Text('Flipkart'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
