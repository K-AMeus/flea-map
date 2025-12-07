import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _googleLoading = false;
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

      if (webClientId == null || webClientId.isEmpty) {
        throw Exception('GOOGLE_WEB_CLIENT_ID has not been set');
      }

      await GoogleSignIn.instance.initialize(
        clientId: Platform.isIOS ? iosClientId : null,
        serverClientId: webClientId,
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw Exception('No ID token found');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        setState(() {
          _googleLoading = false;
        });
        return;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _googleLoading = false;
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _googleLoading = false;
      });
    }
  }

  Widget _buildGoogleLogo() {
    return Image.network(
      'http://pngimg.com/uploads/google/google_PNG19635.png',
      width: 24,
      height: 24,
      fit: BoxFit.cover,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      minimumSize: const Size(double.infinity, 50),
    );

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    label: Text('Email'),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: _emailValidator,
                  autovalidateMode: AutovalidateMode.disabled,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    label: Text('Password'),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: _passwordValidator,
                  autovalidateMode: AutovalidateMode.disabled,
                ),
                const SizedBox(height: 24),
                FilledButton(
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
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Something went wrong. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  style: buttonStyle,
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
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
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Something went wrong. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade400, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _googleLoading
                    ? SizedBox(
                        height: 50,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        icon: _buildGoogleLogo(),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          );
  }
}
