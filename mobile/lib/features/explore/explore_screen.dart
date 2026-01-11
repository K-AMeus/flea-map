import 'dart:async';
import 'package:flutter/material.dart';

import '../shared/model/shop.dart';
import '../shared/service/shop_service.dart';
import '../shared/service/favorite_service.dart';
import '../shared/utils/shop_utils.dart';
import '../shared/widgets/shop_list_item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

enum FilterOption { bestRated, openNow }

class _ExploreScreenState extends State<ExploreScreen> {
  final _shopService = ShopService();
  final _favoriteService = FavoriteService();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _loading = true;
  List<Shop> _shops = [];
  Set<String> _favoriteIds = {};
  String _searchQuery = '';
  final Set<FilterOption> _activeFilters = {};

  List<Shop> get _filteredShops {
    List<Shop> shops = _shops.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      shops = shops
          .where((shop) => shop.name.toLowerCase().contains(query))
          .toList();
    }

    if (_activeFilters.contains(FilterOption.openNow)) {
      shops = shops.where((shop) => isShopOpenNow(shop.openingHours)).toList();
    }

    if (_activeFilters.contains(FilterOption.bestRated)) {
      shops.sort((a, b) {
        final ratingA = a.rating ?? 0;
        final ratingB = b.rating ?? 0;
        return ratingB.compareTo(ratingA);
      });
    }

    return shops;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _favoriteService.favoritesChanged.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _favoriteService.favoritesChanged.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search shops...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                    onChanged: _onSearchChanged,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Best Rated'),
                        avatar: _activeFilters.contains(FilterOption.bestRated)
                            ? null
                            : const Icon(Icons.star, size: 18),
                        selected: _activeFilters.contains(
                          FilterOption.bestRated,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _activeFilters.add(FilterOption.bestRated);
                            } else {
                              _activeFilters.remove(FilterOption.bestRated);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Open Now'),
                        avatar: _activeFilters.contains(FilterOption.openNow)
                            ? null
                            : const Icon(Icons.access_time, size: 18),
                        selected: _activeFilters.contains(FilterOption.openNow),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _activeFilters.add(FilterOption.openNow);
                            } else {
                              _activeFilters.remove(FilterOption.openNow);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                              return ShopListItem(
                                shop: shop,
                                openingHoursText: getTodayOpeningHours(
                                  shop.openingHours,
                                ),
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
