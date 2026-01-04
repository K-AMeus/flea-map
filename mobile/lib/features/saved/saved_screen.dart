import 'package:flutter/material.dart';
import '../shared/model/shop.dart';
import '../shared/service/favorite_service.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _favoriteService = FavoriteService();
  bool _loading = true;
  List<Shop> _favoriteShops = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteShops();
    _favoriteService.favoritesChanged.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoriteService.favoritesChanged.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    _loadFavoriteShops(forceRefresh: true);
  }

  Future<void> _loadFavoriteShops({bool forceRefresh = false}) async {
    try {
      final favoriteShops = await _favoriteService.getFavoriteShops(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _favoriteShops = favoriteShops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTodayOpeningHours(Shop shop) {
    if (shop.openingHours == null) return 'Hours not available';

    final now = DateTime.now();
    const dayNames = [
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
      appBar: AppBar(title: const Text('Saved')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteShops.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved shops',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Navigate to explore to save shops',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFavoriteShops(forceRefresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _favoriteShops.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shop = _favoriteShops[index];
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

class _ShopListItem extends StatefulWidget {
  final Shop shop;
  final String openingHoursText;

  const _ShopListItem({required this.shop, required this.openingHoursText});

  @override
  State<_ShopListItem> createState() => _ShopListItemState();
}

class _ShopListItemState extends State<_ShopListItem> {
  final _favoriteService = FavoriteService();
  bool _isLoadingFavorite = false;

  Future<void> _removeFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      await _favoriteService.removeFavorite(widget.shop.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

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
                  widget.shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      final rating = widget.shop.rating ?? 0;
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
                    if (widget.shop.ratingCount != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.shop.ratingCount})',
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
                  widget.openingHoursText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: _isLoadingFavorite
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.favorite, color: Colors.red),
            onPressed: _removeFavorite,
          ),
        ],
      ),
    );
  }
}
