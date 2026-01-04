import '../../auth/supabase/supabase_client.dart';
import '../model/shop.dart';
import 'local_storage_service.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

  final _localStorage = LocalStorageService();

  List<Shop>? _cachedShops;
  DateTime? _lastFetchTime;

  static const Duration _cacheDuration = Duration(minutes: 15);

  Future<List<Shop>>? _pendingRequest;

  bool get _isCacheValid {
    if (_cachedShops == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<List<Shop>> getShops({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return List.unmodifiable(_cachedShops!);
    }

    if (_pendingRequest != null) {
      return _pendingRequest!;
    }

    _pendingRequest = _fetchShops(forceRefresh: forceRefresh);

    try {
      return await _pendingRequest!;
    } finally {
      _pendingRequest = null;
    }
  }

  Future<List<Shop>> _fetchShops({bool forceRefresh = false}) async {
    try {
      final response = await supabase.from('shops').select();

      _cachedShops = response.map((json) => Shop.fromJson(json)).toList();
      _lastFetchTime = DateTime.now();

      await _localStorage.saveShops(_cachedShops!);

      return List.unmodifiable(_cachedShops!);
    } catch (e) {
      final localShops = await _localStorage.loadShops();

      if (localShops != null && localShops.isNotEmpty) {
        _cachedShops = localShops;
        _lastFetchTime = await _localStorage.getShopsCacheTimestamp();
        return List.unmodifiable(_cachedShops!);
      }

      if (_cachedShops != null) {
        return List.unmodifiable(_cachedShops!);
      }
      rethrow;
    }
  }

  Future<void> preloadFromLocalStorage() async {
    if (_cachedShops != null) return;

    final localShops = await _localStorage.loadShops();
    if (localShops != null && localShops.isNotEmpty) {
      _cachedShops = localShops;
      _lastFetchTime = await _localStorage.getShopsCacheTimestamp();
    }
  }

  void invalidateCache() {
    _cachedShops = null;
    _lastFetchTime = null;
    _localStorage.clearShops();
  }
}
