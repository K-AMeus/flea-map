import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/shop.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _shopsKey = 'cached_shops';
  static const String _shopsTimestampKey = 'cached_shops_timestamp';
  static const String _favoriteIdsKey = 'cached_favorite_ids';
  static const String _favoriteIdsTimestampKey =
      'cached_favorite_ids_timestamp';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  Future<void> saveShops(List<Shop> shops) async {
    final prefs = await _preferences;
    final shopsJson = shops.map((shop) => shop.toJsonWithId()).toList();
    await prefs.setString(_shopsKey, jsonEncode(shopsJson));
    await prefs.setInt(
      _shopsTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<Shop>?> loadShops() async {
    final prefs = await _preferences;
    final shopsString = prefs.getString(_shopsKey);

    if (shopsString == null) return null;

    try {
      final List<dynamic> shopsJson = jsonDecode(shopsString);
      return shopsJson
          .map((json) => Shop.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await clearShops();
      return null;
    }
  }

  Future<DateTime?> getShopsCacheTimestamp() async {
    final prefs = await _preferences;
    final timestamp = prefs.getInt(_shopsTimestampKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearShops() async {
    final prefs = await _preferences;
    await prefs.remove(_shopsKey);
    await prefs.remove(_shopsTimestampKey);
  }

  Future<void> saveFavoriteIds(Set<String> favoriteIds) async {
    final prefs = await _preferences;
    await prefs.setStringList(_favoriteIdsKey, favoriteIds.toList());
    await prefs.setInt(
      _favoriteIdsTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<Set<String>?> loadFavoriteIds() async {
    final prefs = await _preferences;
    final favoritesList = prefs.getStringList(_favoriteIdsKey);
    if (favoritesList == null) return null;
    return favoritesList.toSet();
  }

  Future<void> addFavoriteId(String shopId) async {
    final favorites = await loadFavoriteIds() ?? {};
    favorites.add(shopId);
    await saveFavoriteIds(favorites);
  }

  Future<void> removeFavoriteId(String shopId) async {
    final favorites = await loadFavoriteIds() ?? {};
    favorites.remove(shopId);
    await saveFavoriteIds(favorites);
  }

  Future<DateTime?> getFavoritesCacheTimestamp() async {
    final prefs = await _preferences;
    final timestamp = prefs.getInt(_favoriteIdsTimestampKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearFavorites() async {
    final prefs = await _preferences;
    await prefs.remove(_favoriteIdsKey);
    await prefs.remove(_favoriteIdsTimestampKey);
  }

  Future<void> clearAll() async {
    await clearShops();
    await clearFavorites();
  }
}
