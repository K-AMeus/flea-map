import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../shared/model/shop.dart';
import '../shared/service/shop_service.dart';
import '../shared/service/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final _shopService = ShopService();
  final _locationService = LocationService();
  GoogleMapController? _mapController;
  bool _loading = true;
  List<Shop> _shops = [];
  Set<Marker> _markers = {};
  bool _locationPermissionGranted = false;
  LatLng? _userLocation;

  static const LatLng _tallinnCenter = LatLng(59.4370, 24.7536);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_locationPermissionGranted) {
      _requestLocationPermission();
    }
  }

  Future<void> _initialize() async {
    await _requestLocationPermission();
    await _loadShops();
  }

  Future<void> _requestLocationPermission() async {
    final granted = await _locationService.requestPermission();

    if (!mounted) return;

    setState(() {
      _locationPermissionGranted = granted;
    });

    if (granted) {
      _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentPosition();

    if (!mounted || position == null) return;

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    // Animate to user location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_userLocation!, 14),
    );
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

  String _getDistanceText(Shop shop) {
    if (_userLocation == null) return '';

    final distanceKm = _locationService.calculateDistanceKm(
      _userLocation!.latitude,
      _userLocation!.longitude,
      shop.lat,
      shop.lng,
    );

    if (distanceKm < 1) {
      return '~${(distanceKm * 1000).toInt()} m away';
    } else {
      return '~${distanceKm.toStringAsFixed(1)} km away';
    }
  }

  void _showShopInfo(Shop shop) {
    final distanceText = _getDistanceText(shop);

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
            if (distanceText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distanceText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
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

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is required to show your position on the map and find nearby shops. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
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
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? _tallinnCenter,
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_userLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14),
                );
              }
            },
            myLocationButtonEnabled: _locationPermissionGranted,
            myLocationEnabled: _locationPermissionGranted,
            mapType: MapType.normal,
          ),
          if (!_locationPermissionGranted)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location disabled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enable location to see your location and distance to nearby shops',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showLocationPermissionDialog,
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_shops.isEmpty && _locationPermissionGranted)
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
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }
}
