import 'package:flutter/material.dart';

import '../shared/model/shop.dart';
import '../shared/service/favorite_service.dart';
import '../shared/utils/shop_utils.dart';
import '../shared/widgets/shop_list_item.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _favoriteService = FavoriteService();
  bool _loading = true;
  List<Shop> _favoriteShops = [];
  final Map<String, bool> _loadingFavorites = {};

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

  Future<void> _removeFavorite(String shopId) async {
    if (_loadingFavorites[shopId] == true) return;

    setState(() {
      _loadingFavorites[shopId] = true;
    });

    try {
      await _favoriteService.removeFavorite(shopId);
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
          _loadingFavorites[shopId] = false;
        });
      }
    }
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
                  return ShopListItem(
                    shop: shop,
                    openingHoursText: getTodayOpeningHours(shop.openingHours),
                    isFavorite: true,
                    onFavoriteToggle: () => _removeFavorite(shop.id),
                    isLoadingFavorite: _loadingFavorites[shop.id] ?? false,
                  );
                },
              ),
            ),
    );
  }
}