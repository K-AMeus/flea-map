import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_client.dart';
import 'login/login_screen.dart';
import '../navigation/navbar.dart';
import '../map/services/shop_service.dart';
import '../map/services/favorite_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Session? _previousSession;

  void _handleAuthStateChange(AuthState authState) {
    final currentSession = authState.session;

    if (_previousSession != null && currentSession == null) {
      ShopService().invalidateCache();
      FavoriteService().invalidateCache();
    }

    _previousSession = currentSession;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          _handleAuthStateChange(snapshot.data!);
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flea Map')),
            body: const LoginScreen(),
          );
        }

        return const MainNavigation();
      },
    );
  }
}
