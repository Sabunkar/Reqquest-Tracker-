import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/requests/presentation/screens/activity_history_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/requests/presentation/screens/dashboard_screen.dart';
import '../../features/requests/presentation/screens/edit_request_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/requests/presentation/screens/request_list_screen.dart';
import '../../features/requests/presentation/screens/review_queue_screen.dart';
import '../../features/requests/presentation/widgets/navigation_scaffold.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String onboardingPath = '/onboarding';
  static const String dashboardPath = '/dashboard';
  static const String requestsPath = '/requests';
  static const String reviewQueuePath = '/review-queue';
  static const String activityHistoryPath = '/activity-history';
  static const String notificationsPath = '/notifications';
  static const String profilePath = '/profile';
  static const String settingsPath = '/settings';
  static const String aboutPath = '/about';
  static const String createRequestPath = '/requests/create';
  static const String requestDetailPath = '/requests/:id';
  static const String editRequestPath = '/requests/:id/edit';

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shellNav');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splashPath,
    routes: [
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: loginPath,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: onboardingPath,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', redirect: (_, _) => splashPath),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationScaffold(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: dashboardPath,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: requestsPath,
            name: 'requests',
            builder: (context, state) => const RequestListScreen(),
          ),
          GoRoute(
            path: reviewQueuePath,
            name: 'review_queue',
            builder: (context, state) => const ReviewQueueScreen(),
          ),
          GoRoute(
            path: activityHistoryPath,
            name: 'activity_history',
            builder: (context, state) => const ActivityHistoryScreen(),
          ),
          GoRoute(
            path: notificationsPath,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: profilePath,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: settingsPath,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: aboutPath,
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: createRequestPath,
        name: 'create_request',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: requestDetailPath,
        name: 'request_detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: editRequestPath,
        name: 'edit_request',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditRequestScreen(requestId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),
  );
}
