import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

/// Auth state stream
@riverpod
Stream<AuthState> authState(Ref ref) {
  return supabase.auth.onAuthStateChange;
}

/// Current user provider
@riverpod
User? currentUser(Ref ref) {
  return supabase.auth.currentUser;
}

/// Auth controller for login/logout operations
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  /// Sign in with Google (OAuth)
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://slapp.fun',
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Send OTP to email
  Future<bool> sendEmailOtp(String email) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://slapp.fun',
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Verify email OTP
  Future<bool> verifyEmailOtp(String email, String otp) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Send OTP to phone number
  Future<bool> sendOtp(String phoneNumber) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Check if this is the user's first login (for welcome dialog)
@riverpod
Future<bool> isFirstLogin(Ref ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  // Check if user has a username set (indicates they've completed onboarding)
  final profile = await supabase
      .from('profiles')
      .select('username')
      .eq('id', user.id)
      .maybeSingle();

  return profile?['username'] == null;
}
