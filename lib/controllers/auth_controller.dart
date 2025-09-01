import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
