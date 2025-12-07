import '../../auth/supabase/supabase_client.dart';
import '../model/shop.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

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

    _pendingRequest = _fetchShops();

    try {
      return await _pendingRequest!;
    } finally {
      _pendingRequest = null;
    }
  }

  Future<List<Shop>> _fetchShops() async {
    try {
      final response = await supabase.from('shops').select();

      _cachedShops = response.map((json) => Shop.fromJson(json)).toList();
      _lastFetchTime = DateTime.now();

      return List.unmodifiable(_cachedShops!);
    } catch (e) {
      if (_cachedShops != null) {
        return List.unmodifiable(_cachedShops!);
      }
      rethrow;
    }
  }

  void invalidateCache() {
    _cachedShops = null;
    _lastFetchTime = null;
  }
}
