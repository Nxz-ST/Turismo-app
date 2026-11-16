import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String termsVersion,
    required bool researchConsent,
  }) {
    // La aceptación queda registrada en la cuenta desde el registro, aunque
    // el correo aún no esté confirmado; luego se copia a user_profiles.
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'terms_version': termsVersion,
        'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
        'research_consent': researchConsent,
      },
    );
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    return _supabase.auth.resetPasswordForEmail(email);
  }
}
