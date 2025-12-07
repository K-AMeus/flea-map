import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase/supabase_client.dart';
import 'login/login_screen.dart';
import '../navigation/navbar.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
