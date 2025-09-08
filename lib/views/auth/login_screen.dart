import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/fcm_token_storage.dart';
import 'package:buildables_neu_todo/views/auth/signup_screen.dart';
import 'package:buildables_neu_todo/views/home/home_screen.dart';
import 'package:buildables_neu_todo/controllers/auth_controller.dart';
import 'package:buildables_neu_todo/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthController _auth = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.login(_emailController.text.trim(), _passwordController.text);
      await saveFcmToken();

      // Re-establish Realtime subscription for notifications table
      final supabase = Supabase.instance.client;
      supabase.channel('public:notifications').unsubscribe();
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        print('Re-establishing Realtime subscription for user_id: $userId');
        supabase
            .channel('public:notifications')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              callback: (payload) async {
                print('Received Realtime notification after login: $payload');
                final notification = payload.newRecord;
                if (notification == null) return;
                if (notification['user_id']?.toString() != userId) return;
                await NotificationService.showLocalNotification(
                  title: notification['title'] as String,
                  body: notification['body'] as String,
                  data: notification['data'] as Map<String, dynamic>,
                );
                try {
                  await supabase
                      .from('notifications')
                      .update({
                        'state': 'displayed',
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('id', notification['id']);
                  print(
                    'Updated notification ${notification['id']} to displayed',
                  );
                } catch (e) {
                  print('Error updating notification state: $e');
                }
              },
            )
            .subscribe((status, [error]) {
              print('Realtime subscription status after login: $status');
              if (error != null) print('Realtime subscription error: $error');
            });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: const Text(
                      'Welcome back, we missed you',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accentYellow,
                      child: const Icon(Icons.lock_open, color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: _navigateToSignup,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
