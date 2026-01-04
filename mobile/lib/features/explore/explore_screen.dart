import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../shared/model/shop.dart';
import '../shared/service/shop_service.dart';
import '../shared/service/favorite_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _shopService = ShopService();
  final _favoriteService = FavoriteService();
  final _searchController = TextEditingController();
  bool _loading = true;
  List<Shop> _shops = [];
  Set<String> _favoriteIds = {};
  String _searchQuery = '';

  List<Shop> get _filteredShops {
    if (_searchQuery.isEmpty) return _shops;
    final query = _searchQuery.toLowerCase();
    return _shops
        .where((shop) => shop.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _favoriteService.favoritesChanged.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoriteService.favoritesChanged.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _onFavoritesChanged() {
    _loadFavoriteIds();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    List<Shop> shops = [];
    Set<String> favoriteIds = {};
    String? errorMessage;

    try {
      shops = await _shopService.getShops(forceRefresh: forceRefresh);
    } catch (e) {
      errorMessage = 'Error loading shops: $e';
    }

    try {
      favoriteIds = await _favoriteService.getFavoriteIds(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      errorMessage ??= 'Error loading favorites: $e';
    }

    if (!mounted) return;

    setState(() {
      _shops = shops;
      _favoriteIds = favoriteIds;
      _loading = false;
    });

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final favoriteIds = await _favoriteService.getFavoriteIds(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _favoriteIds = favoriteIds;
      });
    } catch (e) {}
  }

  Future<void> _toggleFavorite(String shopId) async {
    try {
      await _favoriteService.toggleFavorite(shopId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error favouriting shop: $e'),
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
    final filteredShops = _filteredShops;

    return Scaffold(
      appBar: AppBar(title: const Text('Explore shops')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search shops...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _onSearch(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _onSearch,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),
                // Results
                Expanded(
                  child: _shops.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No shops found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Check back later for new listings',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : filteredShops.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No shops match "$_searchQuery"',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadData(forceRefresh: true),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredShops.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final shop = filteredShops[index];
                              return _ShopListItem(
                                shop: shop,
                                openingHoursText: _getTodayOpeningHours(shop),
                                isFavorite: _favoriteIds.contains(shop.id),
                                onFavoriteToggle: () =>
                                    _toggleFavorite(shop.id),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ShopListItem extends StatelessWidget {
  final Shop shop;
  final String openingHoursText;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _ShopListItem({
    required this.shop,
    required this.openingHoursText,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: shop.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(
                      Icons.store,
                      size: 30,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Shop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
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
          // Favorite button
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    );
  }
}
