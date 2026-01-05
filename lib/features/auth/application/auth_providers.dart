import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

/// Auth state stream
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return supabase.auth.onAuthStateChange;
}

/// Current user provider
@riverpod
User? currentUser(CurrentUserRef ref) {
  return supabase.auth.currentUser;
}

/// Auth controller for login/logout operations
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

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
Future<bool> isFirstLogin(IsFirstLoginRef ref) async {
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
