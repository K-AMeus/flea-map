import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/supabase/supabase_client.dart';
import '../model/shop.dart';
import 'local_storage_service.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final _localStorage = LocalStorageService();

  Set<String>? _cachedFavoriteIds;
  DateTime? _lastFetchTime;

  static const Duration _cacheDuration = Duration(minutes: 5);

  final ValueNotifier<int> favoritesChanged = ValueNotifier(0);

  User? get _currentUser => supabase.auth.currentUser;

  void _notifyFavoritesChanged() {
    favoritesChanged.value++;
  }

  bool get _isCacheValid {
    if (_cachedFavoriteIds == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<bool> isFavorite(String shopId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(shopId);
  }

  Future<Set<String>> getFavoriteIds({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return Set.unmodifiable(_cachedFavoriteIds!);
    }

    try {
      final user = _currentUser;
      if (user == null) {
        _cachedFavoriteIds = {};
        _lastFetchTime = DateTime.now();
        return {};
      }

      final response = await supabase
          .from('user_favourites')
          .select('shop_id')
          .eq('user_id', user.id);

      _cachedFavoriteIds = response
          .map<String>((json) => json['shop_id'] as String)
          .toSet();

      _lastFetchTime = DateTime.now();

      await _localStorage.saveFavoriteIds(_cachedFavoriteIds!);

      return Set.unmodifiable(_cachedFavoriteIds!);
    } catch (e) {
      final localFavorites = await _localStorage.loadFavoriteIds();

      if (localFavorites != null) {
        _cachedFavoriteIds = localFavorites;
        _lastFetchTime = await _localStorage.getFavoritesCacheTimestamp();
        return Set.unmodifiable(_cachedFavoriteIds!);
      }

      if (_cachedFavoriteIds != null) {
        return Set.unmodifiable(_cachedFavoriteIds!);
      }

      rethrow;
    }
  }

  Future<void> addFavorite(String shopId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User must be logged in to add favorites');
      }

      await supabase.from('user_favourites').insert({
        'user_id': user.id,
        'shop_id': shopId,
      });

      _cachedFavoriteIds ??= <String>{};
      _cachedFavoriteIds!.add(shopId);
      _lastFetchTime = DateTime.now();

      await _localStorage.addFavoriteId(shopId);

      _notifyFavoritesChanged();
    } catch (e) {
      invalidateCache();
      rethrow;
    }
  }

  Future<void> removeFavorite(String shopId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User must be logged in to remove favorites');
      }

      await supabase
          .from('user_favourites')
          .delete()
          .eq('user_id', user.id)
          .eq('shop_id', shopId);

      _cachedFavoriteIds?.remove(shopId);
      _lastFetchTime = DateTime.now();

      await _localStorage.removeFavoriteId(shopId);

      _notifyFavoritesChanged();
    } catch (e) {
      invalidateCache();
      rethrow;
    }
  }

  Future<void> toggleFavorite(String shopId) async {
    final isFav = await isFavorite(shopId);
    if (isFav) {
      await removeFavorite(shopId);
    } else {
      await addFavorite(shopId);
    }
  }

  Future<List<Shop>> getFavoriteShops({bool forceRefresh = false}) async {
    try {
      final user = _currentUser;
      if (user == null) {
        return [];
      }

      final response = await supabase
          .from('user_favourites')
          .select('shops(*)')
          .eq('user_id', user.id);

      final shops = response
          .map<Shop>(
            (json) => Shop.fromJson(json['shops'] as Map<String, dynamic>),
          )
          .toList();

      _cachedFavoriteIds = shops.map((s) => s.id).toSet();
      _lastFetchTime = DateTime.now();

      // Update local storage
      await _localStorage.saveFavoriteIds(_cachedFavoriteIds!);

      return shops;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> preloadFromLocalStorage() async {
    if (_cachedFavoriteIds != null) return;

    final localFavorites = await _localStorage.loadFavoriteIds();
    if (localFavorites != null) {
      _cachedFavoriteIds = localFavorites;
      _lastFetchTime = await _localStorage.getFavoritesCacheTimestamp();
    }
  }

  void invalidateCache() {
    _cachedFavoriteIds = null;
    _lastFetchTime = null;
    _localStorage.clearFavorites();
  }
}
