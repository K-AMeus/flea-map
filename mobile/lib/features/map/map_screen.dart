import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models/shop.dart';
import 'services/shop_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _shopService = ShopService();
  GoogleMapController? _mapController;
  bool _loading = true;
  List<Shop> _shops = [];
  Set<Marker> _markers = {};

  static const LatLng _tallinnCenter = LatLng(59.4370, 24.7536);

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
        _markers = _createMarkers(shops);
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

  Set<Marker> _createMarkers(List<Shop> shops) {
    return shops.map((shop) {
      return Marker(
        markerId: MarkerId(shop.id),
        position: LatLng(shop.lat, shop.lng),
        infoWindow: InfoWindow(title: shop.name, snippet: shop.address),
        onTap: () => _showShopInfo(shop),
      );
    }).toSet();
  }

  void _showShopInfo(Shop shop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(shop.category),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            if (shop.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    shop.rating!.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (shop.ratingCount != null)
                    Text(
                      ' (${shop.ratingCount} reviews)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ],
            if (shop.about != null) ...[
              const SizedBox(height: 8),
              Text(shop.about!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _loadShops(forceRefresh: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _tallinnCenter,
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapType: MapType.normal,
          ),
          if (_shops.isEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No shops found. Add some shops in Supabase!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
