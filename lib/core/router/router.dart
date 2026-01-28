import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slapp/features/auth/presentation/screens/auth_screen.dart';
import 'package:slapp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:slapp/features/board/presentation/screens/board_screen.dart';
import 'package:slapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:slapp/main.dart';

part 'router.g.dart';

/// Route names for navigation
abstract class AppRoutes {
  static const String auth = '/auth';
  static const String dashboard = '/';
  static const String board = '/board/:id';
  static const String profile = '/profile';
}

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentUser != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.auth;

      // If not logged in and not going to auth, redirect to auth
      if (!isLoggedIn && !isGoingToAuth) {
        return AppRoutes.auth;
      }

      // If logged in and going to auth, redirect to dashboard
      if (isLoggedIn && isGoingToAuth) {
        return AppRoutes.dashboard;
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.board,
        name: 'board',
        builder: (context, state) {
          final boardId = state.pathParameters['id']!;
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
