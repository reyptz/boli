import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/main_layout.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/two_fa_screen.dart';
import '../../features/profile/presentation/screens/partner_onboarding_screen.dart';
import '../../features/rides/presentation/screens/home_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/marketplace/presentation/screens/food_screen.dart';
import '../../features/rides/presentation/screens/delivery_tracking_screen.dart';
import '../../features/rides/presentation/screens/ride_history_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState is AuthAuthenticated;
      final isRequires2fa = authState is AuthRequires2fa;
      final isLoggingIn = state.uri.path == '/signin' || 
                          state.uri.path == '/signup' || 
                          state.uri.path == '/forgot-password' || 
                          state.uri.path == '/reset-password';
      final isSplash = state.uri.path == '/splash';

      if (authState is AuthInitial || authState is AuthLoading) {
        return '/splash';
      }

      if (isSplash) {
        if (isRequires2fa) return '/2fa';
        if (isAuth) return '/';
        return '/signin';
      }

      if (isRequires2fa && state.uri.path != '/2fa') {
        return '/2fa';
      }

      if (!isAuth && !isLoggingIn && !isRequires2fa) {
        return '/signin';
      }

      if (isAuth && (isLoggingIn || state.uri.path == '/2fa')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/2fa',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TwoFaScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/partner-onboarding',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const PartnerOnboardingScreen(),
          ),
          GoRoute(
            path: '/wallet',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/marketplace',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final lat = extra?['latitude'] as double? ?? 12.6392;
              final lng = extra?['longitude'] as double? ?? -8.0029;
              return MarketplaceScreen(userLat: lat, userLng: lng);
            },
          ),
          GoRoute(
            path: '/delivery-tracking/:orderId',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return DeliveryTrackingScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: '/food',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const FoodScreen(),
          ),
          GoRoute(
            path: '/ride-history',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const RideHistoryScreen(),
          ),
        ],
      ),
    ],
  );
});
