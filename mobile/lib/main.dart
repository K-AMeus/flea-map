import 'package:flutter/material.dart';
import 'features/auth/supabase/supabase_client.dart';
import 'features/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const FleaMapApp());
}

class FleaMapApp extends StatelessWidget {
  const FleaMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flea Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
