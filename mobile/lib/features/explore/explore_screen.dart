import 'package:flutter/material.dart';

import '../map/models/shop.dart';
import '../map/services/shop_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _shopService = ShopService();
  bool _loading = true;
  List<Shop> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops({bool forceRefresh = false}) async {
    try {
      final shops = await _shopService.getShops(forceRefresh: forceRefresh);

      if (!mounted) return;

      setState(() {
        _shops = shops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading shops: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTodayOpeningHours(Shop shop) {
    if (shop.openingHours == null) return 'Hours not available';

    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final today = dayNames[now.weekday - 1];

    final todayHours = shop.openingHours![today];
    if (todayHours == null) return 'Closed today';

    final open = todayHours['open'];
    final close = todayHours['close'];

    if (open == null || close == null) return 'Closed today';

    return 'open today: $open - $close';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No shops found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new listings',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadShops(forceRefresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _shops.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shop = _shops[index];
                  return _ShopListItem(
                    shop: shop,
                    openingHoursText: _getTodayOpeningHours(shop),
                  );
                },
              ),
            ),
    );
  }
}

class _ShopListItem extends StatelessWidget {
  final Shop shop;
  final String openingHoursText;

  const _ShopListItem({required this.shop, required this.openingHoursText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Placeholder image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.store, size: 30, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          // Shop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Rating stars
                    ...List.generate(5, (index) {
                      final rating = shop.rating ?? 0;
                      if (index < rating.floor()) {
                        return const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        );
                      } else if (index < rating) {
                        return const Icon(
                          Icons.star_half,
                          size: 16,
                          color: Colors.amber,
                        );
                      } else {
                        return Icon(
                          Icons.star_border,
                          size: 16,
                          color: Colors.grey.shade300,
                        );
                      }
                    }),
                    if (shop.ratingCount != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${shop.ratingCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  openingHoursText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
