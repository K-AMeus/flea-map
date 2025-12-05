import 'package:flutter/material.dart';
import '../supabase/supabase_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    label: Text('Email'),
                    border: OutlineInputBorder(),
                  ),
                  validator: _emailValidator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    label: Text('Password'),
                    border: OutlineInputBorder(),
                  ),
                  validator: _passwordValidator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() {
                      _loading = true;
                    });
                    final ScaffoldMessengerState scaffoldMessenger =
                        ScaffoldMessenger.of(context);
                    try {
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      await supabase.auth.signInWithPassword(
                        email: email,
                        password: password,
                      );
                    } catch (e) {
                      debugPrint('AuthException: ${e.toString()}');
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Login failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() {
                      _loading = true;
                    });
                    final ScaffoldMessengerState scaffoldMessenger =
                        ScaffoldMessenger.of(context);
                    try {
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      await supabase.auth.signUp(
                        email: email,
                        password: password,
                      );
                    } catch (e) {
                      debugPrint('AuthException: ${e.toString()}');
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Signup failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  child: const Text('Signup'),
                ),
              ],
            ),
          );
  }
}
