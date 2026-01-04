import 'package:flutter/material.dart';
import 'features/auth/supabase/supabase_client.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/shared/service/local_storage_service.dart';
import 'features/shared/service/shop_service.dart';
import 'features/shared/service/favorite_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService().init();
  await initializeSupabase();
  await ShopService().preloadFromLocalStorage();
  await FavoriteService().preloadFromLocalStorage();

  runApp(const FleaMapApp());
}

class FleaMapApp extends StatelessWidget {
  const FleaMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flea Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
